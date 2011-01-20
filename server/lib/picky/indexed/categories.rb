module Indexed
  
  class Categories
    
    attr_reader :categories, :category_hash, :ignore_unassigned_tokens
    
    each_delegate :load_from_cache,
                  :to => :categories
    
    def initialize options = {}
      clear
      
      @ignore_unassigned_tokens = options[:ignore_unassigned_tokens] || false
    end
    
    def clear
      @categories    = []
      @category_hash = {}
    end
    
    def << category
      categories << category
      # Note: This is an optimization, since I need an array of categories.
      #       It's faster to just package it in an array on loading Picky
      #       than doing it over and over with each query.
      #
      category_hash[category.name] = [category]
    end
    
    #
    #
    def possible_combinations_for token
      token.similar? ? similar_possible_for(token) : possible_for(token)
    end
    
    # 
    # 
    def similar_possible_for token
      # Get as many similar tokens as necessary
      #
      tokens = similar_tokens_for token
      # possible combinations
      #
      inject_possible_for tokens
    end
    def similar_tokens_for token
      text = token.text
      categories.inject([]) do |result, category|
        next_token = token
        # TODO We could also break off here if not all the available
        #      similars are needed.
        #
        while next_token = next_token.next_similar_token(category)
          result << next_token if next_token && next_token.text != text
        end
        result
      end
    end
    def inject_possible_for tokens
      tokens.inject([]) do |result, token|
        possible = possible_categories token
        result + possible_for(token, possible)
      end
    end
    
    # Returns possible Combinations for the token.
    #
    # Note: The preselected_categories param is an optimization.
    #
    # TODO Return [] if not ok, nil if needs to be removed?
    #      Somehow unnice, but way to go?
    #
    def possible_for token, preselected_categories = nil
      possible = (preselected_categories || possible_categories(token)).map { |category| category.combination_for(token) }
      possible.compact!
      # This is an optimization to mark tokens that are ignored.
      #
      return if ignore_unassigned_tokens && possible.empty?
      possible # wrap in combinations
    end
    # This returns the possible categories for this token.
    # If the user has already preselected a category for this token,
    # like "artist:moby", if not just return all for the given token,
    # since all are possible.
    #
    # Note: Once I thought this was called too often. But it is not (18.01.2011).
    #
    def possible_categories token
      user_defined_categories(token) || categories
    end
    # This returns the array of categories if the user has defined
    # an existing category.
    #
    # Note: Returns nil if the user did not define one
    #       or if he/she has defined a non-existing one. 
    #
    def user_defined_categories token
      category_hash[token.user_defined_category_name]
    end
    
  end
  
end
module Pickwick
  module API
    module Presenters
      class Search
        include Helpers::Common

        def initialize(args = {})
          @vacancies = args[:vacancies]
          @query     = args[:query]
          @request   = args[:request]

          @base_url  = @request.base_url + @request.path
          @total     = @vacancies.total
          @page      = @query.page
          @per_page  = @query.per_page
          @pages     = (@total / @per_page.to_f).ceil
        end

        def links
          links = {}

          next_page_url     = __page_url(@page + 1)
          previous_page_url = __page_url(@page - 1)

          links[:current]   = __page_url(@page)
          links[:next]      = next_page_url     if next_page_url
          links[:previous]  = previous_page_url if previous_page_url
          links
        end

        def as_json
          json total:     @vacancies.total,
               pages:     @pages,
               page:      @page,
               per_page:  @query.per_page,
               max_score: @vacancies.max_score,
               links:     links,
               vacancies: @vacancies.map(&:public_properties)
        end

        def __page_url(page)
          "#{@base_url}?#{@query.params.merge(page: page, seed: @query.seed).to_param}" if page > 0 && page <= @pages
        end

      end
    end
  end
end

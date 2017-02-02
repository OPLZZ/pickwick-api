# Pickwick::API

This repository represents main API for [http://damepraci.eu](http://damepraci.eu) project.

## Permissions

API is designed to be read-only, write-only or read-write.

* __read__ &mdash; API consumer can read all data stored in elasticsearch cluster
* __write__ &mdash; API consumer can store new job postings and modify them
* __read + write__ &mdash; API consumer can read all data stored in elasticsearch cluster, can store new job postings and modify them

## API endpoints

API currently implements `/vacancies` endpoint which consists of two main parts

* __search__
* __store__

### Search API

Following endpoints require __search__ permission.

#### __GET__ /vacancies.json

Endpoint for job postings search.

##### Parameters

* __location__ &mdash; desired work place location; job postings closer than 50km will be boosted
* __query__ &mdash; search query; search is performed on fields: `title, description, contact.*, employer.*, experience.description, location.*, publisher.*, responsibilities` (each term in query parameter is separated by AND)
* __preference__ &mdash; query which will be boosted (each term in preference parameter is separated by OR)
* __employment_type__ &mdash; job postings with selected type will be boosted; available types: `full-time, part-time, contract, temporary, seasonal, internship`
* __remote__ &mdash; remote jobs will be boosted; available values: `true, false`
* __page__ &mdash; parameter for pagination
* __per_page__ &mdash; number of job postings per page
* __seed__ &mdash; search results are little bit shuffled; shuffle is based on this seed parameter, so you need to provide same seed when paginating to get results in correct order
* __token__ &mdash; consumer token with search permissions

##### Possible responses

* __200__ &mdash; search request was successfully executed

  Example

      curl -i -X GET "http://api.damepraci.cz/vacancies.json?location=50.0741098,14.451515799999997&query=kuchař&token=TOKEN&per_page=25"

      HTTP/1.1 200 OK
      Server: nginx/1.2.1
      Date: Mon, 02 Jun 2014 15:43:41 GMT
      Content-Type: application/json;charset=utf-8
      Content-Length: 36016
      Connection: keep-alive
      Access-Control-Allow-Origin: *
      X-Content-Type-Options: nosniff
      
      {
        "total":403,
        "pages":17,
        "page":1,
        "per_page":25,
        "max_score":0.9727054,
        "links":{
          "current":"http://api.damepraci.cz/vacancies.json?&captures%5B%5D=json&format=json&location=50.0741098%2C14.451515799999997&page=1&per_page=25&query=kucha%C5%99&seed=1401723821&token=TOKEN",
          "next":"http://api.damepraci.cz/vacancies.json?&captures%5B%5D=json&format=json&location=50.0741098%2C14.451515799999997&page=2&per_page=25&query=kucha%C5%99&seed=1401723821&token=TOKEN"
        },
        "vacancies":[
          {
            "id":"199c9ab044d65132c232c277579fefd1e64f991e",
            "distance":3.6056001066677,
            "score":0.9727054,
            "title":"kuchař (kuchařka)",
            ..... rest ommited .....
          },
          {
            "id":"48105a37c1db7076d47134fd2361aa2154400022",
            "distance":29.1735628224113,
            "score":0.7993828,
            "title":"kuchař / kuchařka",
            ..... rest ommited .....
          },
          .....
        ]
      }

  Note: You can paginate using `links` in search response.

* __401__ &mdash; unauthorized; you provided invalid token or API consumer doesn't have read permissions





#### __GET__ /vacancies/ID.json

For getting individual vacancy by it's ID.

##### Parameters

* __id__ &mdash; id of the required job posting
* __token__ &mdash; consumer token with search permissions

##### Possible responses

* __200__ &mdash; job posting was found and returned as response body

  Example

      curl -i -X GET "http://api.damepraci.cz/vacancies/b11bc0a27f1725d66ce003897113e12e39172f28.json?token=TOKEN"

      HTTP/1.1 200 OK
      Server: nginx/1.2.1
      Date: Mon, 02 Jun 2014 13:59:53 GMT
      Content-Type: application/json;charset=utf-8
      Content-Length: 1226
      Connection: keep-alive
      Access-Control-Allow-Origin: *
      X-Content-Type-Options: nosniff
      
      {
        "vacancy":{
          "id":"b11bc0a27f1725d66ce003897113e12e39172f28",
          "distance":null,
          "score":null,
          "title":"pekař",
          "description":"Pracoviště Podhradní Lhota - noční výroba pečiva\n - vyučení v oboru výhodou, vhodné i pro absolventy flexibilita, spolehlivost\n- kontakt osobně na pracovišti nebo telefonicky Po-Pá (11:00 - 20:00 hod.)",
          "industry":null,
          "responsibilities":null,
          "number_of_positions":null,
          "employment_type":"full-time",
          "remote":false,
          "location":{
            "street":"Podhradní Lhota 107",
            "city":"Podhradní Lhota",
            "region":null,
            "zip":"768 71",
            "country":"Czech Republic",
            "coordinates":{
              "lat":49.4207499,
              "lon":17.7950512
            }
          },
          "experience":null,
          "employer":{
            "name":null,
            "company":"K****** D*****"
          },
          "publisher":null,
          "contact":{
            "email":"**********@seznam.cz",
            "name":"K******* D******, majitel",
            "phone":"+420 *** *** ****"
          },
          "compensation":null,
          "start_date":"2014-06-02T00:00:00Z",
          "expiration_date":"2014-06-26T18:00:10Z",
          "created_at":"2014-05-27T18:00:10Z",
          "updated_at":"2014-05-27T18:39:42Z"
        }
      }

* __404__ &mdash; job posting was not found

  Example

      curl -i -X GET "http://api.damepraci.cz/vacancies/123.json?token=TOKEN"

      HTTP/1.1 404 Not Found
      Server: nginx/1.2.1
      Date: Mon, 02 Jun 2014 13:55:53 GMT
      Content-Type: application/json;charset=utf-8
      Content-Length: 48
      Connection: keep-alive
      Access-Control-Allow-Origin: *
      X-Content-Type-Options: nosniff
      
      {
        "error":"requested document was not found"
      }

* __401__ &mdash; unauthorized; you provided invalid token or API consumer doesn't have read permissions

  Example

      curl -i -X GET "http://api.damepraci.cz/vacancies/554b774c6f55f9f58a096af30ec30d15b918ee9.json?token=INVALID_TOKEN"

      HTTP/1.1 401 Unauthorized
      Server: nginx/1.2.1
      Date: Mon, 02 Jun 2014 13:58:34 GMT
      Content-Type: application/json;charset=utf-8
      Content-Length: 29
      Connection: keep-alive
      Access-Control-Allow-Origin: *
      X-Content-Type-Options: nosniff
      
      {
        "error":"Access denied"
      }


#### __POST__ /vacancies/bulk.json

Endpoint for getting multiple job postings by their IDS.

_Note: This endpoint will be merged with `/vacancies/id.json` endpoint in the future._

##### Parameters

* __ids__ &mdash; id of the searched job posting
* __token__ &mdash; consumer token with search permissions

##### Possible responses

* __200__ &mdash; job postings were found and returned as response body in the same order as requested.

  Example

      curl -i -X POST "http://api.damepraci.cz/vacancies/bulk.json?token=TOKEN" -d 'ids[]=fbc80353789446e618942237c178984a3f456078&ids[]=b11bc0a27f1725d66ce003897113e12e39172f28&ids[]=123'

      HTTP/1.1 200 OK
      Server: nginx/1.2.1
      Date: Mon, 02 Jun 2014 14:22:39 GMT
      Content-Type: application/json;charset=utf-8
      Content-Length: 2659
      Connection: keep-alive
      Access-Control-Allow-Origin: *
      X-Content-Type-Options: nosniff
      
      {
        "vacancies":[
          {
            "id":"fbc80353789446e618942237c178984a3f456078",
            ..... rest ommited .....
          },
          {
            "id":"b11bc0a27f1725d66ce003897113e12e39172f28",
            ..... rest ommited .....
          }
        ]
      }
      
* __401__ &mdash; unauthorized; you provided invalid token or API consumer doesn't have read permissions
  
  Example

      curl -i -X POST "http://api.damepraci.cz/vacancies/bulk.json?token=123" -d 'ids[]=123'

      HTTP/1.1 401 Unauthorized
      Server: nginx/1.2.1
      Date: Mon, 02 Jun 2014 14:25:09 GMT
      Content-Type: application/json;charset=utf-8
      Content-Length: 29
      Connection: keep-alive
      Access-Control-Allow-Origin: *
      X-Content-Type-Options: nosniff
      
      {
        "error":"Access denied"
      }

### Store API

Following endpoints require __store__ permission.

#### __DELETE__ /vacancies/ID.json

Endpoint for deleting job postings by their `id`. API consumer can delete job postings created by her/him only.

#### Parameters

* __id__ &mdash; job posting id
* __token__ &mdash; consumer token with store permissions

##### Possible responses

* __204__ &mdash; job posting successfully deleted

  Example

      curl -i -X DELETE "http://api.damepraci.cz/vacancies/b588ee68f6e3b1721bec9473dc215143f55cf399.json?token=TOKEN"

      HTTP/1.1 204 No Content
      Server: nginx/1.2.1
      Date: Mon, 02 Jun 2014 16:22:57 GMT
      Connection: keep-alive
      Access-Control-Allow-Origin: *
      X-Content-Type-Options: nosniff


* __404__ &mdash; job posting was not found
  
  Example

      curl -i -X DELETE "http://api.damepraci.cz/vacancies/b588ee68f6e3b1721bec9473dc215143f55cf399.json?token=TOKEN"

      HTTP/1.1 404 Not Found
      Server: nginx/1.2.1
      Date: Mon, 02 Jun 2014 16:26:04 GMT
      Content-Type: application/json;charset=utf-8
      Content-Length: 48
      Connection: keep-alive
      Access-Control-Allow-Origin: *
      X-Content-Type-Options: nosniff
      
      {
        "error":"requested document was not found"
      }

* __401__ &mdash; unauthorized; you provided invalid token or API consumer doesn't have store permissions

#### __POST__ /vacancies.json

Endpoint for storing job postings. Each job posting should be formatted as `JSON` on separate line.

Required fields are: `title, description, contact, location`. In `contact` field, at least `phone` or `email` field is required.

##### Parameters

* __payload__ &mdash; `JSON` representation of job posting (same format as API returns)

  You can create multiple job postings in one request.

  Each `JSON` representation must be on new line (separated by `\n`).

  If you want to update existing job posting, you need to provide `id` field in `JSON` representation of job posting.
* __token__ &mdash; consumer token with store permissions

##### Possible responses

* __200__ &mdash; request successfully executed
  
  In the responded `results` array, there will be result for each `JSON` representation of job posting in the exact order as in request.

  When job posting is created, `id` of the stored job posting is returned.

  Possible result statuses:

  * __201__ &mdash; new job posting was created
  * __200__ &mdash; job posting was updated
  * __400__ &mdash; bad request; some required fields are probably missing
  * __409__ &mdash; same job posting already exists and was created by different API consumer
  * __500__ &mdash; something bad happened; see `errors` field

  Example

      curl -i -X POST "http://api.damepraci.cz/vacancies.json?token=TOKEN" -d 'payload={"title":"nadpis prace", "contact": {"email":"kontakt@mail.cz"} }
      {"title":"nadpis", "description":"krátký popis pozice","contact": {"email":"contact@email.com"}, "location" : { "city" : "Prague" } }'

      HTTP/1.1 200 OK
      Server: nginx/1.2.1
      Date: Mon, 02 Jun 2014 16:11:59 GMT
      Content-Type: application/json;charset=utf-8
      Content-Length: 362
      Connection: keep-alive
      Access-Control-Allow-Origin: *
      X-Content-Type-Options: nosniff
      
      {
        "results":[
          {
            "id":null,
            "version":null,
            "status":400,
            "errors":{
              "description":[
                "can't be blank"
              ],
              "location":[
                "can't be blank"
              ]
            }
          },
          {
            "id":"b588ee68f6e3b1721bec9473dc215143f55cf399",
            "version":1,
            "status":201,
            "errors":{}
          }
        ]
      }

* __401__ &mdash; unauthorized; you provided invalid token or API consumer doesn't have store permissions

## Installation

    git clone https://github.com/OPLZZ/pickwick-api.git
    cd pickwick-api

... install the required rubygems:

    bundle install

... prepare elasticsearch indices

    bundle exec rake setup

You can set CONSUMER_TOKEN environment variable to create API consumer with _search_ and _store_ permissions.

    CONSUMER_TOKEN=123 bundle exec rake setup

You can set ELASTICSEARCH_API_URL to set URL of running elasticsearch

    ELASTICSEARCH_API_URL=http://localhost:9250 bundle exec rake setup

You can set FORCE=true to recreate elasticsearch indices

    FORCE=true CONSUMER_TOKEN=123 ELASTICSEARCH_API_URL=http://localhost:9250 bundle exec rake setup

So this command recreates indices and creates API consumer with token 123.

## Usage

Before server run, several environment variables needs to be set.

    export ELASTICSEARCH_API_URL='elasticsearch url'
    export SIDEKIQ_REDIS_URL='https://github.com/OPLZZ/pickwick-workers redis url'

... and run server

    bundle exec puma

API should be accessible at http://localhost:9292.

----

##Funding
<a href="http://esfcr.cz/" target="_blank"><img src="https://www.damepraci.cz/assets/oplzz_banner_en.png" alt="Project of Operational Programme Human Resources and Employment No. CZ.1.04/5.1.01/77.00440."></a>
The project No. CZ.1.04/5.1.01/77.00440 was funded from the European Social Fund through the Operational Programme Human Resources and Employment and the state budget of Czech Republic.

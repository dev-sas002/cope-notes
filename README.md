# CopeNotes

This is simple application where users can be registered, and create messages. After every one minute, every subscriber will receive a unique message on email. Once a subscriber has received all messages, they will not receive any more.
You can also set subscriber active or inactive. If a subscriber is inactive he will not receive any emails.
This is a scalable solution will work for large number of users.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Installing

* Ruby version
 3.0.2

 ```
 rvm install 3.0.2
 ```
* Database
postgresql
redis

```
brew install postgres
brew install redis
```
```
cd cope-notes
```

**Install Gems**
```
bundle install
```

**Database creation**

```
  rails db:create
  rails db:migrate
```

**Populate Database with initial data**
```
rails db:seed
```
### Docker

* I have also dockerize the application. Please install docker desktop and no need install any other dependency.
* Please run following command and application is ready to use
```
docker-compose up
```
### Using APP

* I have added postman collection under postman directory, please import and use it.
* Run app on port 3000
```
bundle exec rails s
```
**API headers**
```
    {
      'Content-Type' => 'application/json',
      'Accept'       => 'application/json'
    }
```
**Register subscriber**
- URL
````
http://localhost:3000/api/v1/subscribers
````
- Request method
```
Post
```
- sample Payload
```
{
  "email": "client@example.com",
  "name": "client"
}
```

**Update subscriber status**
- URL
````
http://localhost:3000/api/v1/subscribers/1
````
- Request method
```
PATCH
```

**Destroy subscriber**
- URL
````
http://localhost:3000/api/v1/subscribers/1
````
- Request method
```
Destroy
```

**Register new message**
- URL
````
http://localhost:3000/api/v1/messages
````
- Request method
```
Post
```
- sample Payload
```
{
  "text": "sample text"
}
```

**Update message**
- URL
````
http://localhost:3000/api/v1/messages/1
````
- Request method
```
PATCH
```
- sample Payload
```
{
  "text": "updated sample text"
}
```

**Destroy message**
- URL
````
http://localhost:3000/api/v1/messages/1
````
- Request method
```
Destroy
```

### Development Environment

* This is ready to use working app. It will send emails to actual users if provide smtp server, user and token etc.

* But for development environment I have configured letter opener, by using it we can see all sent emails.
please visit

````
http://localhost:3000/letter_opener/
````
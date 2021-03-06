# API tutorial - build an api provider app 
(part 1)

## **What is an API?**

Put in simple words an "API is a program which lets the user use methods of your application from outside of the application". I will create a REST API here which will implement a CRUD ( create, read, update, delete ) operation on the users table from outside of the application. I assume you all have implemented CRUD for the user in an application before. The API implementation will remain the same, with a few differences listed below.

=> In a normal case, you have a form new.html.erb and edit.html.erb, which provides UI to the user to register themselves and edit their profile respectively. But for an API you do not need any view, as a user does not interact with your application directly, instead, you specify the data that the third party should send to you.

=> There will be no new and edit action in controller, as we do not need any view here

=> We will not do any redirect in our controller action, but just return some data with a status code of success or failure. We may return data in json or xml. As per convention, you should return data as requested by the client calling your API services, so for json request return json data and for xml return xml data.

=> An API does not have any user interface like navigation links or forms to fill out by the user etc. For an API you need to document how it works so that a third party can use it easily. I will write the documentation for the API we create here in STEP 4

STEP 0: setting things up

check to see what versions of rails you have installed

	gem list rails --local
	
look for something like this

	** LOCAL GEMS **
	rails (5.1.1, 5.1.0)
	
we want to install 4.2.1 and 3.2.13 as well let's start with 4.x

	gem install rails -v '4.2.1' -V --no-ri --no-rdoc
	
then again for 3.x

	gem install rails -v '3.2.13' -V --no-ri --no-rdoc
	
Now check the install with the gem list command

	gem list rails --local

We are ready now. we are going to build this out with a Rails 3 app with postgres and no test framework (I prefer rspec)

    rails __3.2.13__ new api_providerdemo -T -d=postgresql

next let's add some useful gems to our gemfile...

    group :development, :test do
        gem 'better_errors'
        gem 'pry-rails'
        gem 'binding_of_caller'
    end

open database.yml 

remove the username under development, test and production and back at the command line do the usual

	rake db:create 
	rake db:migrate

open routes.rb

STEP 1: writing the routes

    namespace :api do
    	resources :users, :defaults => { :format => 'json' }
    end

I have put the routes, within api **namespace**, in this way, it will not conflict with users controller of your actual application, 
if you have one. If you do not have any, you can simply use  **resources :users, :defaults => { :format => 'json' }** , but I suggest to always use a namespace and group all the controllers related to your API in the "api" folder inside your app/controllers directory only.

Also, I have set the default **:format** here as **json** . If you do not set it, rails will consider it as an html request if the user does not pass any format. Now from the command line type the following

    $ rails generate model User first_name:string last_name:string email:string password:string password_confirmation:string temp_password:string

or since :string is the default....

    $ rails generate model User first_name last_name email password password_confirmation temp_password


Once done do the normal rake db:create , rake db:migrate and then travel to your model/user.rb file and enter the following...

**STEP 2: generating the model**

    class User < ActiveRecord::Base
      attr_accessible :first_name, :last_name, :email, :password, :password_confirmation, 
                      :temp_password

      validates :email, :first_name, :last_name, :presence =>true
      validates_uniqueness_of :email
    end

In model we have validated email and other things, the user calling our API must provide these things. 
Thus while creating a user the caller must pass :email, :first_name and :last_name. 
we will generate password dynamically and let the user change it later on.

Note: Below on line one of our users controller we have "class Api::UsersController". 
You will need to create an "api" folder like so... app/controllers/api/users_controller.rb directory.

**STEP 3 : generating the users controller**

    class Api::UsersController < ApplicationController
      http_basic_authenticate_with :name => "thefonso", :password => "rebelbase"

      skip_before_filter :authenticate_user! # we do not need authentication here
      before_filter :fetch_user, :except => [:index, :create]
  
      def fetch_user
         @user = User.find_by_id(params[:id])
      end
  
      def index
        @users = User.all
        respond_to do |format|
          format.json { render json: @users }
          format.xml { render xml: @users }
        end
      end
  
      def show
        respond_to do |format|
          format.json { render json: @user }
          format.xml { render xml: @user }
        end
      end
  
      def create
        @user = User.new(params[:user])
        @user.temp_password = ('a'..'z').to_a.shuffle[0,8].join
        respond_to do |format|
          if @user.save
            format.json { render json: @user, status: :created }
            format.xml { render xml: @user, status: :created }
          else
            format.json { render json: @user.errors, status: :unprocessable_entity }
            format.xml { render xml: @user.errors, status: :unprocessable_entity }
          end
        end
      end
  
      def update
        respond_to do |format|
          if @user.update_attributes(params[:user])
            format.json { head :no_content, status: :ok }
            format.xml { head :no_content, status: :ok }
          else
            format.json { render json: @user.errors, status: :unprocessable_entity }
            format.xml { render xml: @user.errors, status: :unprocessable_entity }
          end
        end
      end
  
      def destroy
        respond_to do |format|
          if @user.destroy
            format.json { head :no_content, status: :ok }
            format.xml { head :no_content, status: :ok }
          else
            format.json { render json: @user.errors, status: :unprocessable_entity }
            format.xml { render xml: @user.errors, status: :unprocessable_entity }
          end
        end
      end
    end

With step 3, your API is ready. But how will others use it? You need to tell them how so let's document the API.

**STEP 4 : creating API Documentation**

API USAGE DOCUMENT
___________________________________________________________________
Basic Authentication:

    username: thefonso
    password: rebelbase

Content Type :

   application/xml or application/json

Body:

   You can pass xml or json data in Body
   
   sample json body

    {
     "email" : "test@yopmail.com", 
     "first_name" : "alfonso", 
     "last_name" : "rush"
    }

   Sample xml body

    <user>
      <email>"test@yopmail.com">
      <first-name>alfonso</first-name>
      <last-name>rush</last-name>
    </user>

NOTE : Content Type should be set to application/xml for xml data in body 
and to application/json for json data in body

API Requests:
<pre>
=> listing users
    url: http://localhost:3000/api/users
    method: GET
    body : not needed

=> Retrieving User detail
    url: http://localhost:3000/api/users/:id 
    method: GET
    body : not needed

=> creating users
    url: http://localhost:3000/api/users
    method: Post
    Body : It can be xml or json

=> Updating User
    url: http://localhost:3000/api/users/:id 
    method: PUT
    Body : It can be xml or json
  
=> Deleting User 
    url: http://localhost:3000/api/users/:id 
    method: DELETE
    body : not needed
</pre>
  
**STEP 5: testing the API**

You need to write a REST client to use any API. 
I have explained [how to do so in this post](https://github.com/thefonso/api_consumer/blob/master/readme.md).

You may also try it out by installing a REST client in your browser.
I have explained installing [a REST client for Firefox here](https://github.com/thefonso/api_provider/blob/master/rest_firefox_client.md).

You will find method, url, body, header, authentication etc fields there, fill in the details from the documentation in step 4 above. On submitting the details, you will get back a response. Hope it works for you and you receive enlighttenment on the basics of understanding API creation :)

View tutorial readme pages / code:

part 1 - [Build an API provider](https://github.com/thefonso/api_provider/)

part 2 - [a REST client for Firefox here](https://github.com/thefonso/api_provider/blob/master/rest_firefox_client.md)

part 3 - [How to build a REST client](https://github.com/thefonso/api_consumer/)

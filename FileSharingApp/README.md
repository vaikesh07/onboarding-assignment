# README

File Sharing Application
A simple web application built with Ruby on Rails for uploading, sharing, and managing files.

Prerequisites
Before you begin, ensure you have the following installed:

Ruby: 2.6.6

Rails: 6.0.6.1

Database: SQLite3

Node.js

Yarn

Setup and Installation
Clone the repository:

Bash

git clone <your-repository-url>
cd FileSharingApp
Install Ruby:

Bash

# For Intel Macs or after setting up Rosetta on Apple Silicon
rbenv install 2.6.6
rbenv local 2.6.6
Install Bundler:

Bash

gem install bundler

Bash

bundle install

Install JavaScript Dependencies:

Bash

yarn install

Set up the Database:

Bash

rails db:create
rails db:migrate

Running the Application
Start the Rails server:

Bash

rails server

Open your browser and navigate to http://localhost:3000.

Running the Tests
To run the full RSpec test suite, use the following command:

Bash

bundle exec rspec
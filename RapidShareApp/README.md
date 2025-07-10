# RapidShare: File Sharing Application

A web application built with Ruby on Rails that allows users to sign up, upload files, and share them with others via unique, public links. This project uses industry-standard gems for robust authentication and file management.

---

## System Requirements

To run this project locally, you will need the following versions installed:

* **Ruby:** `2.6.6`
* **Rails:** `6.0.3.6`
* **Database:** SQLite3
* **Node.js & Yarn**

### Special Instructions for Apple Silicon (M1/M2/M3) Macs

This project requires an older version of Ruby that is not natively compatible with Apple Silicon. To set up the environment on an M1/M2/M3 Mac, you will need to install and compile Ruby using Rosetta 2. This typically involves setting up a separate instance of Homebrew for the Intel (x86_64) architecture.

---

## Key Gems Used

This project leverages several key gems to provide its core functionality:

* **`devise`**: A flexible and powerful authentication solution for Rails. It handles all user management, including sign-up, login, logout, and password recovery.
* **`carrierwave`**: A simple and clean solution for file uploads in Rails. It manages the process of attaching files to model records and storing them.
* **`rspec-rails`**: The primary testing framework used for this project. It provides a behavior-driven development (BDD) environment for writing unit and integration tests.
* **`factory_bot_rails`**: A library for creating test data (factories). It allows for the easy creation of model objects for use in tests.
* **`shoulda-matchers`**: Provides simple, one-liner tests for common Rails functionality, such as model validations and associations.

---

## Local Setup and Installation

Follow these steps to get the application running on your local machine.

1.  **Clone the Repository**
    ```bash
    git clone <your-repository-url>
    cd RapidShareApp
    ```

2.  **Install Ruby**
    Using a version manager like `rbenv` is highly recommended.
    ```bash
    rbenv install 2.6.6
    rbenv local 2.6.6
    ```

3.  **Install Dependencies**
    Install the required Ruby gems and JavaScript packages.
    ```bash
    gem install bundler
    bundle install
    yarn install
    ```

4.  **Database Setup**
    Create the database and run the migrations to set up the application's tables.
    ```bash
    rails db:create
    rails db:migrate
    ```

---

## Running the Application

1.  **Start the Rails Server:**
    ```bash
    rails server
    ```
2.  **Access the Application:**
    Open your web browser and navigate to `http://localhost:3000`.

---

## Running the Test Suite

To run the full RSpec test suite and ensure all functionality is working as expected, use the following command:

```bash
bundle exec rspec

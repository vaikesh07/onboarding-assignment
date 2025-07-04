# File Sharing 101

A simple web application built with Ruby on Rails for uploading, sharing, and managing files. This project was built according to the specifications outlined in the product document.

## System Requirements

* **Ruby:** `2.6.6`
* **Rails:** `6.0.x`
* **Database:** SQLite3
* **Node.js & Yarn**


## Local Setup and Installation

1.  **Clone the Repository**
    ```bash
    git clone <your-repository-url>
    cd FileSharingApp
    ```

2.  **Install Ruby**
    Use a version manager like `rbenv` to install the correct Ruby version.
    ```bash
    # For Intel Macs:
    rbenv install 2.6.6

    # For Apple Silicon Macs (requires Rosetta and Intel Homebrew):
    arch -x86_64 rbenv install 2.6.6
    ```
    Set the local version for the project:
    ```bash
    rbenv local 2.6.6
    ```

3.  **Install Bundler & Dependencies**
    Install the Bundler gem and then install all required Ruby and JavaScript dependencies.
    ```bash
    gem install bundler
    bundle install
    yarn install
    ```

4.  **Database Setup**
    Create and migrate the database to set up the necessary tables.
    ```bash
    rails db:create
    rails db:migrate
    ```

## Running the Application

1.  **Start the Rails Server:**
    ```bash
    rails server
    ```
2.  **Access the Application:**
    Open your web browser and navigate to `http://localhost:3000`.

## Running Tests

To run the full RSpec test suite, use the following command:
```bash
bundle exec rspec
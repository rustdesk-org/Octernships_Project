

Hi , i had applied for rust-desk octernship but github classroom did not generated any repository for me where i can submit my code so i created a fork of this repo and created a new branch . opening a pull request to review from mentors.

SYSTEM REQUIREMENTS -

Flutter SDK
Rust Lang
Polkit  (check with  '"polkit --version" command or if you have installed it enable it via "sudo systemctl start polkit" )

HOW TO RUN -

Go to Rust_Native Folder and after opening the terminal in the folder, execute the following functions.

" cargo build "
" cargo run ( it will start the server )"

Now , open flutter_app folder and run

"flutter run -d linux"

it will prompt the user to input password details if enabled otherwise it will show the output in flutter window.

NOTE - as i had tested and developed it on ubuntu i encountered an exception "no linux desktop configured" for this run the following commands -

"flutter config --enable-linux-desktop"
"flutter create --platforms=windows,macos,linux"

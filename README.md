# Authenticate-with-polkit
Assignment Submission For GitHub Octernship Assessment of RustDesk-Org

<h1> Greetings </h1><br>
Welcome to the RustDesk-Org Octernship Assessment submission! This project consists of two main components: Frontend and RustBackend, each responsible for its specific role.

The RustBackend component executes the command ls -la /root/ on a Linux kernel and posts the result on the web as an API.

On the other hand, the Frontend component comprises a Flutter Application that calls the "get" WebAPI and displays the retrieved data on the screen.

<h1>Important Note</h1><br>
The project guide suggests using Polkit for privilege elevation. However, I have limited familiarity with Polkit, and despite my numerous attempts to accomplish the task using Polkit in Rust, I was unable to complete it successfully.

Therefore, this assignment utilizes the "sudo" command along with the required command, i.e., "ls -la /root/", in Rust to fulfill the requirements.

The <a href="https://github.com/rustdesk-org/Octernships_Project">project guide</a> suggest the priviledge elevation to be done via Polkit
but I'm relatively unfamiliar with Polkit and despite my several attempts to figure out how to do the process using polkit in Rust,
I was still unable to complete the task. 

Hence, this Assignment uses running "sudo" along with the required command i.i. "ls -la /root/" in Rust to complete the Assignment.

<h1> Navigating Through The Project </h1>

<h3> Prequesites </h3>

Make sure you are on a linux machine and have compilers of <a href="https://www.redhat.com/sysadmin/install-rust-linux">Rust</a> and <a href= "https://docs.flutter.dev/get-started/install/linux">Flutter</a> languages installed in your system.
 
<h3> Now </h3>

1) Clone the repository into your local system 
```
git clone https://github.com/ADS-bot/octernship
```
2) Navigate to the directory where you cloned the repository.

<h3> We need to Run our Backend Server before the flutter app runs </h3>

3) Navigate to the RustBackend Folder and then the rust_backend folder using 
```
cd RustBackend/rust_backend
```

4) Now to run the Rust project enter the following command in the terminal. This will start a backend server on LocalHost Port 3000.
```
cargo run
```
5) Now open a new terminal and navigate to the cloned folder again.
6) Navigate to the FrontEnd folder and then the octernship_ui folder using the following command
```
cd FrontEnd/octernship_ui
```
7) Now start the flutter project in debug mode on Linux machine using - 
```
flutter run -d linux
```
8) Once the flutter App starts, It will automatically send a Get Request on the Rust local Server which will then run the Command in the terminal.
9) Now Navigate to the terminal where the Rust BackEnd is active and you'll be asked the password for elevating the user. Enter the Password and Click Enter.
10) Now Navigate to the Flutter app and you'll see the output displayed on the HomeScreen as required.

<h1> Thanks for Your Attention</h1><br>
Thank you for taking the time to explore this Octernship Assessment submission. If you have any questions or require further assistance, please feel free to reach out. 

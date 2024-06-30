# Run PM2 as service on Windows Server in modern way

[Documentation](https://medium.com/@gzthomasliang/run-pm2-as-service-on-windows-server-in-modern-way-286b9f4b8228)


PM2 is an excellent tool for managing Node.js application processes.Unfortunately, PM2 has no built-in startup support for Windows.Running PM2 as a Windows service can be challenging.The traditional approach has five methods:

1. node-windows
This version is still in beta and was last updated two years ago. Currently, only Node.js applications can be run as services, and the tool is overly simplistic, lacking a powerful PM2 daemon.
2. tjanczuk/iisnode or Azure/iisnode
This tool enables hosting Node.js applications within IIS, but it has not been updated since 2017.
3. jon-hall/pm2-windows-service
This project is no longer supported or maintained.
4. marklagendijk/node-pm2-windows-startup
pm2-windows-startup adds an entry to the registry to start pm2 after user login. Because it does not create a service, PM2 will not be running until a user has logged into the user interface, and will halt when they log out. It has not been updated since 2015.
5. jessety/pm2-installer
This project leverages the latest version of node-windows and a series of PowerShell scripts to create a custom Windows service. This provides an effective solution for running PM2 as a service.But it has two issues:
    - I encountered difficulties creating a service on newer Windows Server versions, like Windows Server 2022/2025. The process resulted in some error message, I gust that the “node-windows” library might be outdated and lacks compatibility with the latest Windows Server releases.
    - The automatically installed PM2 version is not the latest one.

Through studying the above solution, I have developed a method to optimise PM2 running as a service, using simple and reliable technology(only 100+ line powershell script).    
1. Installing and Configuring PM2 and npm with a PowerShell 7 Script.
2. winsw/winsw,WinSW is compatible with the latest Windows Server versions, and its replacement, NSSM, is also a good option.

## The PowerShell 7 Script
Requirements

1. Windows Server 2016/2019/2022/2025
2. Node.js 18+
3. PowerShell 7 LTS

download [pm2-win-service-install.ps1](https://github.com/gzthomasliang/pm2-service/blob/main/pm2-service-install.ps1) and execute.

To install PM2 as a Windows service using PowerShell 7, execute the `pm2-win-service-install.ps1` script. Following execution, verify the installation by checking for both the “PM2” service within Windows Services and the “pm2” command within your PowerShell console.

To start your Node.js application using PM2, execute the command `pm2 start [your-application-name]`. Once running, save the PM2 configuration by executing `pm2 save`. You can then reboot your Windows Server machine to verify that the PM2 service is functioning correctly.
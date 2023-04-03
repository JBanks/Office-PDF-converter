# This file is a series of notes that I took while finding a way to get the docker container to work.
# Each piece has very particular quirks that need to be addressed.


## This conainter will not run on anything that does not support Windows Containers.
## It will not even run using the docker WSL2 engine.  It must be run on pure windows servers.
# Prepare microsoft office  #https://blog.devgenius.io/install-microsoft-office-in-windows-container-ce05877138fd
FROM mcr.microsoft.com/windows:20H2 AS build

WORKDIR C:\\odtsetup
ADD https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_11617-33601.exe odtsetup.exe
RUN odtsetup.exe /quiet /norestart /extract:C:\\odtsetup

FROM mcr.microsoft.com/windows:20H2 AS download

WORKDIR C:\\odtsetup
COPY --from=build C:\\odtsetup\\setup.exe .
ADD config.xml .
RUN setup.exe /download C:\\odtsetup\\config.xml

FROM mcr.microsoft.com/windows:20H2

WORKDIR C:\\odtsetup
COPY --from=build C:\\odtsetup\\setup.exe .
COPY --from=download C:\\odtsetup\\Office .
ADD config.xml .
RUN setup.exe /configure C:\\odtsetup\\config.xml
# https://stackoverflow.com/questions/10837437/interop-word-documents-open-is-null
WORKDIR /
RUN rmdir /s /q C:\\odtsetup 
RUN powershell -Command new-object -comobject word.application
RUN mkdir C:\\Windows\\SysWOW64\\config\\systemprofile\\Desktop

VOLUME C:\\data




# For oracle, we need to run server core (.net framework, not .net core)
# slide 15, 29 from: https://www.oracle.com/technetwork/topics/dotnet/tech-info/oow18windowscontainers-5212844.pdf
## From Oracle Slides 35-3?:
FROM microsoft/windowsservercore:1709 as builder
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
ENV NODE_VERSION 8.12.0
ENV IC_FILENAME instantclient-basic-windows.x64-18.3.0.0.0dbru.zip
ENV IC_FILENAME2 instantclient-sqlplus-windows.x64-18.3.0.0.0dbru.zip
ENV IC_FOLDER instantclient_18_3
RUN Invoke-WebRequest $('https://nodejs.org/dist/v{0}/node-v{0}-win-x64.zip' -f $env:NODE_VERSION) -OutFile 'node.zip' -UseBasicParsing ; \
    Expand-Archive node.zip -DestinationPath C:\ ; \
    Rename-Item -Path $('C:\node-v{0}-win-x64' -f $env:NODE_VERSION) -NewName 'C:\nodejs';
COPY $IC_FILENAME instantclient.zip
COPY $IC_FILENAME2 instantclient2.zip
COPY msvcr120.dll c:/windows/system32/msvcr120.dll
RUN Expand-Archive instantclient.zip -DestinationPath C:\; \
    Expand-Archive instantclient2.zip -DestinationPath C:\; \
    Rename-Item -Path $($env:IC_FOLDER-f $env:NODE_VERSION) -NewName 'C:\instantclient'; 
RUN $env:PATH = 'C:\instantclient;C:\nodejs;{0}' -f $env:PATH ; \
    [Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::Machine)
RUN mkdir c:/demo
WORKDIR c:/demo
COPY package.json package.json
COPY server.js server.js
RUN npminstall
FROM microsoft/windowsservercore:1709
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
COPY --from=builder /nodejs /nodejs
COPY --from=builder /instantclient /instantclient
COPY --from=builder /demo /demo
COPY --from=builder /windows/system32/msvcr120.dll /nodejs/msvcr120.dll
WORKDIR c:/demo
ARG SETX=/M
RUN setx /M PATH $('C:\instantclient;C:\nodejs;'+ $Env:PATH)
CMD ["c:/nodejs/npm.cmd", "start"]

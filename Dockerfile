# Prepare microsoft office  #https://blog.devgenius.io/install-microsoft-office-in-windows-container-ce05877138fd
FROM mcr.microsoft.com/windows:20H2 AS office_builder

WORKDIR C:/odtsetup
ADD https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_11617-33601.exe odtsetup.exe
RUN odtsetup.exe /quiet /norestart /extract:C:\\odtsetup

# I don't know why this is separte from the previous one, but I stole it so I'm leaving it as-is. -JB
FROM mcr.microsoft.com/windows:20H2 AS office_download

WORKDIR C:/odtsetup
COPY --from=officebuilder C:/odtsetup/setup.exe .
ADD config.xml .
RUN setup.exe /download C:/odtsetup/config.xml

# Prepare oracle instantclient  #https://www.oracle.com/technetwork/topics/dotnet/tech-info/oow18windowscontainers-5212844.pdf
FROM mcr.microsoft.com/windows:20H2 AS oracle_builder

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ENV IC_FILENAME instantclient-basic-windows.x64-18.3.0.0.0dbru.zip
ENV IC_FILENAME2 instantclient-sqlplus-windows.x64-18.3.0.0.0dbru.zip
ENV IC_FOLDER instantclient_18_3

COPY $IC_FILENAME instantclient.zip
COPY $IC_FILENAME2 instantclient2.zip
COPY msvcr120.dll c:/windows/system32/msvcr120.dll
RUN Expand-Archive instantclient.zip -DestinationPath C:/; \
    Expand-Archive instantclient2.zip -DestinationPath C:/; \
    Rename-Item -Path $($env:IC_FOLDER -f $env:NODE_VERSION) -NewName 'C:\instantclient';
RUN $env:PATH = 'C:\instantclient;{0}' -f $env:PATH ; \
    [Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::Machine)

#Prepare python installation  #https://blog.devgenius.io/creating-python-docker-image-for-windows-nano-server-151e1ab7188a
FROM mcr.microsoft.com/windows:20H2 AS python_builder

RUN [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; \
    Invoke-WebRequest -UseBasicParsing -Uri "https://www.python.org/ftp/python/$env:PYTHON_RELEASE/python-$env:PYTHON_VERSION-embed-amd64.zip" -Out 'Python.zip'; \
    Expand-Archive -Path "Python.zip"; \
    Invoke-WebRequest -UseBasicParsing -Uri "$env:PYTHON_GET_PIP_URL" -OutFile 'Python\get-pip.py';

RUN [String]::Format('@set PYTHON_PIP_VERSION={0}', $env:PYTHON_PIP_VERSION) | Out-File -FilePath 'Python\pipver.cmd' -Encoding ASCII; \
    $FileVer = [System.Version]::Parse([System.Diagnostics.FileVersionInfo]::GetVersionInfo('Python\python.exe').ProductVersion); \
    $Postfix = $FileVer.Major.ToString() + $FileVer.Minor.ToString(); \
    Remove-Item -Path "Python\python$Postfix._pth"; \
    Expand-Archive -Path "Python\python$Postfix.zip" -Destination "Python\Lib"; \
    Remove-Item -Path "Python\python$Postfix.zip"; \
    New-Item -Type Directory -Path "Python\DLLs";


# Bring it all together
FROM mcr.microsoft.com/windows:20H2

COPY --from=python_builder C:/Temp/Python C:/Python
ENV PYTHONPATH C:\\Python;C:\\Python\\Scripts;C:\\Python\\DLLs;C:\\Python\\Lib;C:\\Python\\Lib\\plat-win;C:\\Python\\Lib\\site-packagesRUN setx.exe /m PATH %PATH%;%PYTHONPATH% && \
    setx.exe /m PYTHONPATH %PYTHONPATH% && \
    setx.exe /m PIP_CACHE_DIR C:\Users\ContainerUser\AppData\Local\pip\Cache && \
    reg.exe ADD HKLM\SYSTEM\CurrentControlSet\Control\FileSystem /v LongPathsEnabled /t REG_DWORD /d 1 /f
RUN assoc .py=Python.File && \
    assoc .pyc=Python.CompiledFile && \
    assoc .pyd=Python.Extension && \
    assoc .pyo=Python.CompiledFile && \
    assoc .pyw=Python.NoConFile && \
    assoc .pyz=Python.ArchiveFile && \
    assoc .pyzw=Python.NoConArchiveFile && \
    ftype Python.ArchiveFile="C:\Python\python.exe" "%1" %* && \
    ftype Python.CompiledFile="C:\Python\python.exe" "%1" %* && \
    ftype Python.File="C:\Python\python.exe" "%1" %* && \
    ftype Python.NoConArchiveFile="C:\Python\pythonw.exe" "%1" %* && \
    ftype Python.NoConFile="C:\Python\pythonw.exe" "%1" %*
RUN call C:\Python\pipver.cmd && \
    %COMSPEC% /s /c "echo Installing pip==%PYTHON_PIP_VERSION% ..." && \
    %COMSPEC% /s /c "C:\Python\python.exe C:\Python\get-pip.py --disable-pip-version-check --no-cache-dir pip==%PYTHON_PIP_VERSION%" && \
    echo Removing ... && \
    del /f /q C:\Python\get-pip.py C:\Python\pipver.cmd && \
    echo Verifying install ... && \
    echo   python --version && \
    python --version && \
    echo Verifying pip install ... && \
    echo   pip --version && \
    pip --version && \
    echo Complete.

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
COPY --from=oracle_builder /instantclient /instantclient
COPY --from=oracle_builder /windows/system32/msvcr120.dll /nodejs/msvcr120.dll
ARG SETX=/M
RUN setx /M PATH $('C:\instantclient;'+ $Env:PATH)

WORKDIR C:/odtsetup
COPY --from=officebuilder C:/odtsetup/setup.exe .
COPY --from=officedownload C:/odtsetup/Office .
ADD config.xml .
RUN setup.exe /configure C:/odtsetup/config.xml
# https://stackoverflow.com/questions/10837437/interop-word-documents-open-is-null
WORKDIR /
RUN rmdir /s /q C:/odtsetup
RUN powershell -Command new-object -comobject word.application
RUN mkdir C:/Windows/SysWOW64/config/systemprofile/Desktop

RUN mkdir C:/worker
WORKDIR C:/worker
COPY ./src .
COPY ./Test_documents .

RUN pip install -r requirements.txt

VOLUME C:/data

CMD ["python", "src/unit_test.py"]
FROM mcr.microsoft.com/dotnet/sdk:8.0

COPY 'entrypoint.ps1' '/'

ENTRYPOINT [ "/entrypoint.ps1" ]

# Dockerfile
FROM ubuntu:20.04

# Installiere benötigte Pakete
RUN apt-get update && \
    apt-get install -y wget gpg software-properties-common

# Füge Microsoft-Repository hinzu und installiere SQL Server-Tools
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/20.04/prod.list)" && \
    apt-get update && \
    apt-get install -y mssql-tools unixodbc-dev

# Installiere Azure Data Studio (Linux-Version)
RUN wget -qO azure-data-studio.deb https://go.microsoft.com/fwlink/?linkid=2150014 && \
    apt install -y ./azure-data-studio.deb && \
    rm azure-data-studio.deb

# Setze den Arbeitsordner
WORKDIR /workspace

# Starte Azure Data Studio
CMD ["azure-data-studio"]


#docker build -t azure-data-studio .
#docker run -it --rm --network=my_network -e DISPLAY=host.docker.internal:0 azure-data-studio


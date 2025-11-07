FROM amazonlinux:2

# Install dependencies needed for our script

RUN yum update -y && \
    yum install -y aws-cli tar gzip which && \
    yum clean all

# Creating a directory inside the container to hold our application

WORKDIR /app 

# Copy the backup script from the local machine to the container    

COPY ../backup.sh .

# Make the backup script executable

RUN chmod +x backup.sh


# Setting the entrypoint to the backup script

ENTRYPOINT ["./backup.sh"]
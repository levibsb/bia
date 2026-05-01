GNU nano 5.8                                                                                                                     check-disponibilidade.sh
url="http://bia-alb-559988653.us-east-1.elb.amazonaws.com/"
docker build -t check_disponibilidade -f Dockerfile_checkdisponibilidade .
docker run --rm -ti -e URL=$url check_disponibilidade

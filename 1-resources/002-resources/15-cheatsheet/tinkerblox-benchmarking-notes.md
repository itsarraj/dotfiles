RAG Pipeline(llama3:70b + Nomic embed)

One time.

Step 1

aws ecr get-login-password --region ap-south-1 | \
docker login --username AWS \
--password-stdin 864899848864.dkr.ecr.ap-south-1.amazonaws.com

Step 2

free -h

sudo sync
echo 3 | sudo tee /proc/sys/vm/drop_caches

Step 3 

sudo systemctl restart docker
sudo  systemctl restart containerd.service

at restart this must be clean
› docker system df
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          0         0         0B        0B
Containers      0         0         0B        0B
Local Volumes   0         0         0B        0B
Build Cache     0         0         0B        0B

--- 
need cpu,ram,cache - avg,max,usage

> wait 5 minutes, in netdata we set the time for 5 minutes and inside compute 
> we get the compute->cpu then maximize the cpu graph and below there expand compute periods
> note max,avg values in summary_engg metrics deamon start (observed 5 minutes) CPU peak and avg
> for resource usage we multiply avg*timetakeninseconds 

> for ram RAM Max, RAM Average, RAM resource usage
ram->memory->usage ->maximize inside there we have 3rd tab (drill down)
copy used - avg, max 
our system rams is in GB but from netdata we got GiB
GiB to GB = ? (?/systemram)*100

To convert GiB (gibibytes) to GB (gigabytes):
GB = GiB × 1.073741824

after GiB to GB of ram used avg max
resource usage = 300 sec * avg
usually 5 miniutes


now we need cache
cached 2098.88% 0% 2 2.05 2.08
buffers 72.68% 0% 0.07 0.07 0.07
add buffer+cached  max and avg
convert GiB to GB
then 
GiB to GB = ? (?/systemram)*100



---



sudo ./target/debug/docker images

sudo ./target/debug/docker system-df

sudo du -h --max-depth=1 /var/lib/docker

df -h

Step 4
pulling ollama
> when we are doing this do › date
Fri Jul  3 02:51:32 PM IST 2026
we need date before running 
> time docker run -d -v ollama_data:/root/.ollama -p 8081:11434 --name ollama ollama/ollama
after it ran , means pulled there will be time 
use the start time we get from date command and the end time that was returned from above pull commmand
```
› time docker run -d -v ollama_data:/root/.ollama -p 8081:11434 --name ollama ollama/ollama
Unable to find image 'ollama/ollama:latest' locally
latest: Pulling from ollama/ollama
789c8b668600: Downloading [=================================================> ]  103.8MB/104.8MB
3cd6fe4fb7f2: Download complete
cb259a83ac3d: Pull complete
a86f5e677975: Downloading [==>                                                ]  159.4MB/3.098GB
^C
real	0m50.679s
user	0m0.065s
sys	0m0.076s
›
```
> Fri Jul  3 02:51:32 PM IST 2026 start time >>>>>> end time real	0m50.679s add them 
> we get time period 
> go to netdata set that time period and start taking notes on cpu ram cache






time docker run -d \
  -v ollama_data:/root/.ollama \
  -p 8083:11434 \
  --name ollama \
  864899848864.dkr.ecr.ap-south-1.amazonaws.com/ollama-0.30.8:latest

Step 5

for this also repeat above process 
time docker exec -it ollama ollama pull llama3:70b


free -h

docker system df 

docker stop ollama
docker rm ollama

docker system prune -a

docker volume prune -a


--------------------------

after running that .py file 
after inference is over 
Throughput Inital will be output of that script 
simply put those in sheet as they are scripted to output in that script


on very top of sheet there are 
Startup Time (Sec)
>>Cold Startup Time (Sec) ->>>> this is ollama pull time in seconds
>>LLama pulling (From Ollama Registry)  ->>>>> this is model pull time in seconds


import requests
import threading
import time

# Replace with your NodePort service's IP and Port
NODE_PORT_SERVICE_IP = '<clsuter ip of worrker or master node>'
NODE_PORT = '<port number>'

# Initial number of threads to simulate concurrent users
INITIAL_NUM_THREADS = 10
# Initial number of requests per thread
INITIAL_REQUESTS_PER_THREAD = 100
# Interval in seconds to increase the load
INCREASE_INTERVAL = 5  # 1 minute
# Increment step for threads and requests
THREAD_INCREMENT = 5
REQUESTS_INCREMENT = 50

def send_requests(num_requests):
    url = f'http://{NODE_PORT_SERVICE_IP}:{NODE_PORT}'
    for _ in range(num_requests):
        try:
            response = requests.get(url)
            print(f'Response Code: {response.status_code}')
        except requests.exceptions.RequestException as e:
            print(f'Request failed: {e}')

def start_load_test(num_threads, num_requests):
    threads = []
    for _ in range(num_threads):
        thread = threading.Thread(target=send_requests, args=(num_requests,))
        thread.start()
        threads.append(thread)
    
    for thread in threads:
        thread.join()

if __name__ == "__main__":
    num_threads = INITIAL_NUM_THREADS
    num_requests = INITIAL_REQUESTS_PER_THREAD
    
    while True:
        print(f"Starting load test with {num_threads} threads and {num_requests} requests per thread.")
        start_load_test(num_threads, num_requests)
        
        print(f"Load test completed with {num_threads} threads and {num_requests} requests per thread.")
        print(f"Increasing load in {INCREASE_INTERVAL} seconds...")
        
        # Wait before increasing load
        time.sleep(INCREASE_INTERVAL)
        
        # Increase the load
        num_threads += THREAD_INCREMENT
        num_requests += REQUESTS_INCREMENT
import ipaddress

def ip_to_cidr(start_ip, n):
    start = int(ipaddress.IPv4Address(start_ip))
    result = []

    while n > 0:
        max_size = start & -start
        step = max_size.bit_length() - 1
        while (1 << step) > n:
            step -= 1
        cidr = f"{ipaddress.IPv4Address(start)}/{32 - step}"
        result.append(cidr)
        start += 1 << step
        n -= 1 << step

    return result

def generate_cidr_list(ip_list):
    ip_list = sorted(set(ip_list), key=lambda ip: int(ipaddress.IPv4Address(ip)))
    result = []

    i = 0
    while i < len(ip_list):
        start_ip = ip_list[i]
        count = 1
        while i + count < len(ip_list):
            expected_ip = int(ipaddress.IPv4Address(start_ip)) + count
            current_ip = int(ipaddress.IPv4Address(ip_list[i + count]))
            if current_ip != expected_ip:
                break
            count += 1
        result.extend(ip_to_cidr(start_ip, count))
        i += count

    return result

def main():
    input_file = 'from_ip_list.txt'
    output_file = 'result_cidr_list.txt'

    with open(input_file, 'r') as f:
        ip_list = [line.strip() for line in f if line.strip()]

    cidr_list = generate_cidr_list(ip_list)

    with open(output_file, 'w') as f:
        for cidr in cidr_list:
            f.write(cidr + '\n')

if __name__ == "__main__":
    main()

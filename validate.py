true_data = open('pi-million.txt', 'r').read()

user_data = open('pi-computed.txt', 'r').read().replace('\n', '')


valid = True
i = 0

while i < min(len(user_data), len(true_data)):
    if true_data[i] != user_data[i]:
        print(f"Computed value doesn't match true value at index {i} (got {user_data[i]} instead of {true_data[i]})")
        valid = False
        break
    i += 1
    
if valid:
    # Ignore the "3." for decimals, ignore the period for the digits
    print(f"Your Pi value is valid up to {i-2} decimals ({i-1} digits).")
        
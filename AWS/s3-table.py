import sys
from prettytable import PrettyTable

def main(input_file, output_file):
    table = PrettyTable()
    table.field_names = ["Bucket", "Region", "MFA Delete", "Lifecycle"]

    with open(input_file, 'r') as infile:
        for line in infile:
            columns = line.strip().split(',', 3)
            if len(columns) == 4:
                bucket, region, mfa_delete, lifecycle = columns
                table.add_row([bucket, region, mfa_delete, lifecycle])
            else:
                print(f"Skipping line due to incorrect format: {line.strip()}")

    with open(output_file, 'w') as outfile:
        outfile.write(table.get_string())

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
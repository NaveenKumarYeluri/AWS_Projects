import os

# Configuration
TARGET_SIZE_MB = 8
MAX_BYTES = TARGET_SIZE_MB * 1024 * 1024

# Define Directories
BASE_DIR = os.getcwd()
FULL_FILES_DIR = os.path.join(BASE_DIR, 'FullFiles')
SPLIT_FILES_DIR = os.path.join(BASE_DIR, 'SplitFiles')

def split_csv_by_size(input_folder, output_folder, prefix):
    os.makedirs(output_folder, exist_ok=True)

    # Find the CSV in the input folder
    input_files = [f for f in os.listdir(input_folder) if f.endswith('.csv')]
    if not input_files:
        print(f"No CSV found in {input_folder}")
        return

    input_filepath = os.path.join(input_folder, input_files[0])
    print(f"Splitting {input_filepath}")

    with open(input_filepath, 'r', encoding='utf-8') as infile:
        header = infile.readline()
        file_count = 1
        current_out_file = None
        current_size = 0

        for line in infile:
            # Open a new split file if we don't have one active
            if current_out_file is None:
                out_path = os.path.join(output_folder, f"{prefix}_split_{file_count}.csv")
                current_out_file = open(out_path, 'w', encoding='utf-8')
                current_out_file.write(header)
                current_size = len(header.encode('utf-8'))

            # Write the row and track byte size
            current_out_file.write(line)
            current_size += len(line.encode('utf-8'))

            # If we hit the 8MB limit, close the file so a new one triggers
            if current_size >= MAX_BYTES:
                current_out_file.close()
                current_out_file = None
                file_count += 1

        # Close the final file if it didn't perfectly hit the limit
        if current_out_file is not None:
            current_out_file.close()

    print(f"Finished splitting {prefix}. Created {file_count} files in {output_folder}")

if __name__ == "__main__":
    # 1. Split Institute Data
    split_csv_by_size(
        input_folder=os.path.join(FULL_FILES_DIR, 'institute'),
        output_folder=os.path.join(SPLIT_FILES_DIR, 'institute'),
        prefix='institute'
    )

    # 2. Split Applicant Data
    split_csv_by_size(
        input_folder=os.path.join(FULL_FILES_DIR, 'applicant'),
        output_folder=os.path.join(SPLIT_FILES_DIR, 'applicant'),
        prefix='applicant'
    )

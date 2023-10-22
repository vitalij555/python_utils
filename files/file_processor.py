import os
import shutil

def process_and_move_file(input_filename, subfolder_name, new_extension, process_file_function=None):
    if not new_extension.startswith('.'):
        new_extension = '.' + new_extension

    abs_input_path = os.path.abspath(input_filename)
    

    input_directory = os.path.dirname(abs_input_path)
    
    subfolder_path = os.path.join(input_directory, subfolder_name)
    os.makedirs(subfolder_path, exist_ok=True)
    

    output_filename = os.path.splitext(os.path.basename(abs_input_path))[0] + new_extension
    output_path = os.path.join(subfolder_path, output_filename)
    

    if process_file_function:
        process_file_function(abs_input_path, output_path)

    
    return (output_path, output_filename)



def example_process_file(input_path, output_path):
    with open(input_path, 'r') as infile, open(output_path, 'w') as outfile:
        for line in infile:
            # Example: reverse each line and write to the output file
            outfile.write(line[::-1])

# Usage:
result_path, result_filename = process_and_move_file('input.txt', 'processed_files', '.out', example_process_file)
print(result_path, result_filename)


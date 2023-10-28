import os
import shutil

def process_and_move_file(input_filename, subfolder_name, new_extension, process_file_function=None):
    if not new_extension.startswith('.'):
        new_extension = '.' + new_extension

    abs_input_path = os.path.abspath(input_filename)
    

    input_directory = os.path.dirname(abs_input_path)
    
    subfolder_path = os.path.abspath(os.path.join(input_directory, "../", subfolder_name))
    os.makedirs(subfolder_path, exist_ok=True)
    

    output_filename = os.path.splitext(os.path.basename(abs_input_path))[0] + new_extension
    output_path_file = os.path.join(subfolder_path, output_filename)
    

    if process_file_function:
        process_file_function(abs_input_path, output_path_file)

    
    return output_path_file



# Usage:
# result_path, result_filename = process_and_move_file('input.txt', 'processed_files', '.out', example_process_file)
# print(result_path, result_filename)


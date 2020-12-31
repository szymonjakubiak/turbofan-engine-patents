import os

import epo_ops

client = epo_ops.Client(accept_type='json', key='.......', secret='.........')
# response = client.published_data_search(cql="ti=turbofan-engine", range_begin=1, range_end=3, constituents=['biblio'])



total_results = 1253
batch_size = 20
raw_data_dir = 'raw_data'



for start_index in range(1, total_results+1, batch_size):
    end_index = start_index + batch_size - 1
    if end_index > total_results:
        end_index = total_results
    print(f"Processing call for range [{start_index} {end_index}]")
    response = client.published_data_search(cql="ti=turbofan-engine", range_begin=start_index, range_end=end_index, constituents=['biblio'])
    with open(os.path.join(raw_data_dir, f"data_{start_index}_{end_index}.json"), 'w') as out_file:
        out_file.write(response.text)
    if not response.ok:
        print(f"Error, status code: {response.status_code}")

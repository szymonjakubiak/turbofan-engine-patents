import json, os
import pandas as pd
import numpy as np


raw_data_dir = 'raw_data'

rows = []
for file_name in os.listdir(raw_data_dir):
    print(file_name)
    with open(os.path.join(raw_data_dir, file_name), 'r') as data_file:
        loaded_json = json.load(data_file)
        documents_list = loaded_json['ops:world-patent-data']['ops:biblio-search']['ops:search-result']['exchange-documents']
        for document in documents_list:
            bibliography = document['exchange-document']['bibliographic-data']
            parties = bibliography['parties']
            fetched_data = {}

            # Applicants
            if 'applicants' not in parties:
                fetched_data['applicant'] = 'independent'
            else:
                try:
                    fetched_data['applicant'] = parties['applicants']['applicant'][0]['applicant-name']['name']['$']
                except:
                    fetched_data['applicant'] = parties['applicants']['applicant']['applicant-name']['name']['$']
            # Number of inventors
            try:
                fetched_data['inventors_nb'] = len(parties['inventors']['inventor'])
            except:
                fetched_data['inventors_nb'] = np.nan
            # Publish date
            fetched_data['pub_date'] = int(bibliography['publication-reference']['document-id'][0]['date']['$'])
            # Country
            fetched_data['country_code'] = document['exchange-document']['@country']
            # Title
            if type(bibliography['invention-title']) == list:
                fetched_data['title'] = bibliography['invention-title'][0]['$']
                for title in bibliography['invention-title']:
                    if title['@lang'] == 'en':
                        fetched_data['title'] = title['$']
            else:
                fetched_data['title'] = bibliography['invention-title']['$']

            rows.append(fetched_data)
df = pd.DataFrame(rows)


df = df.drop_duplicates()

df.loc[:, 'pub_date'] = pd.to_datetime(df['pub_date'], format=r"%Y%m%d")

# Append full country name
df_country = pd.read_csv("country_codes.csv", delimiter=',', names=['country_code', 'country_name'])
df = pd.merge(df, df_country, how='left', on='country_code')


df.to_csv('patents.csv', index=False)

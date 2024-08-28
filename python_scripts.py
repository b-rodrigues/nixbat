from pandas import read_csv

def download_iris(iris_csv_url):
    # Read the CSV file
    df = read_csv(iris_csv_url)

    return df

def process_iris(iris_csv_path):
    # Read the CSV file
    df = read_csv(iris_csv_path)

    # Replace the species numbers with their corresponding names
    species_mapping = {0: "setosa", 1: "virginica", 2: "versicolor"}
    df['species'] = df['species'].replace(species_mapping)

    return df

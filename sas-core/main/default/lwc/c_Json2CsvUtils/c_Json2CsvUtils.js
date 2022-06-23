export function exportCSVFile(headers, totalData,fileTitle){
    if(!totalData || totalData.length === 0){
        return;
    }
    const jsonData = JSON.stringify(totalData);
    const result = convertToCSV(jsonData, headers);
    if(result == null) return;
    const blob = new Blob([result]); // create blob data from the csv string
    const exportedFilename = fileTitle ? fileTitle + '.xlsx': 'export.xlsx';  // set the file name  and extension
    const link = document.createElement("a"); // create a link element to download the file
    link.href = window.URL.createObjectURL(blob); // set the link href to the object url
    link.download = exportedFilename; // set the file name
    link.style.visibility = "hidden"; // make the link invisible
    document.body.appendChild(link); // append the link to the body
    link.click(); // click the link 
    document.body.removeChild(link); // remove the link from the body

}

export function convertToCSV(objArray, headers) {

    const actualHeaderKeys = Object.keys(headers); // create an array of the headers
    const headersToShow = Object.values(headers); // create an array of the headers to show as CSV headers
    const data =  typeof objArray != 'object' ? JSON.parse(objArray): objArray; // convert the string to json object

    let rowEnd = '\n';
    let csvString = '';


    // Array.from() method returns an Array object from any object with a length property or an iterable object.

    csvString += headersToShow.join(',');
    csvString += rowEnd;

     // loop through the data and add each row to the csv string
     for(let i=0; i < data.length; i++){
        let colValue = 0;

        // loop through the headers and add each column to the csv string
        for(let key in actualHeaderKeys) {

            if(actualHeaderKeys.hasOwnProperty(key)) {

                // Key value 
                // Ex: Id, Name
                let rowKey = actualHeaderKeys[key]; 
                // add , after every value except the first.
                if(colValue > 0){
                    csvString += ',';
                }
                // get the value from the data and add to csv 
                let value = data[i][rowKey] === undefined ? '' : data[i][rowKey];
                csvString += '"'+ value +'"';
                colValue++;
            }
        }
        csvString += rowEnd;
    }
    return csvString;
}

    export function exportPassengerDataInExcel(objArray, headers) {

    const actualHeaderKeys = Object.keys(headers); // create an array of the headers
    const headersToShow = Object.values(headers); // create an array of the headers to show as Excel headers
    const data =  typeof objArray != 'object' ? JSON.parse(objArray): objArray; // convert the string to json object
        // Prepare a html table
        let doc = '<table>';
        // Add styles for the table
        doc += '<style>';
        doc += 'table, th, td {';
        doc += '    border: 1px solid black;';
        doc += '    border-collapse: collapse;';
        doc += '}';
        doc += '</style>';
        // Add all the Table Headers
        doc += '<tr>';
        this.headersToShow.forEach(element => {
            doc += '<th>'+ element +'</th>'
        });
        doc += '</tr>';
        // Add the data rows
        this.data.forEach(record => {
            doc += '<tr>';
            doc += '<th>'+record.Id+'</th>'; 
            doc += '<th>'+record.FirstName+'</th>'; 
            doc += '<th>'+record.LastName+'</th>';
            doc += '<th>'+record.Email+'</th>'; 
            doc += '</tr>';
        });
        doc += '</table>';
        var element = 'data:application/vnd.ms-excel,' + encodeURIComponent(doc);
        let downloadElement = document.createElement('a');
        downloadElement.href = element;
        downloadElement.target = '_self';
        // use .csv as extension on below line if you want to export data as csv
        downloadElement.download = 'Contact Data.xls';
        document.body.appendChild(downloadElement);
        downloadElement.click();

    }

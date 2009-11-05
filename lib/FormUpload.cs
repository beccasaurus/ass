using System;
using System.IO;
using System.Net;
using System.Text;
using System.Collections;
using System.Collections.Specialized;
using System.Collections.Generic;

public static class FormUpload
{
	private static readonly Encoding encoding = Encoding.UTF8;

	public static HttpWebResponse MultipartFormDataPost(string postUrl, string userAgent, Dictionary<string, object> postParameters)
	{
		string formDataBoundary = "-----------------------------28947758029299";
		string contentType = "multipart/form-data; boundary=" + formDataBoundary;
 
		byte[] formData = GetMultipartFormData(postParameters, formDataBoundary);
 
		return PostForm(postUrl, userAgent, contentType, formData);
	}
	private static HttpWebResponse PostForm(string postUrl, string userAgent, string contentType, byte[] formData)
	{
		HttpWebRequest request = WebRequest.Create(postUrl) as HttpWebRequest;
 
		if (request == null)
		{
			throw new NullReferenceException("request is not a http request");
		}
 
		// Set up the request properties
		request.Method = "POST";
		request.ContentType = contentType;
		request.UserAgent = userAgent;
		request.CookieContainer = new CookieContainer();
		request.ContentLength = formData.Length;  // We need to count how many bytes we're sending. 
 
		using (Stream requestStream = request.GetRequestStream())
		{
			// Push it out there
			requestStream.Write(formData, 0, formData.Length);
			requestStream.Close();
		}
 
		return request.GetResponse() as HttpWebResponse;
	}
 
	private static byte[] GetMultipartFormData(Dictionary<string, object> postParameters, string boundary)
	{
		Stream formDataStream = new System.IO.MemoryStream();
 
		foreach (var param in postParameters)
		{
			if (param.Value is FileParameter)
			{
				FileParameter fileToUpload = (FileParameter)param.Value;
 
				// Add just the first part of this param, since we will write the file data directly to the Stream
				string header = string.Format("--{0}\r\nContent-Disposition: form-data; name=\"{1}\"; filename=\"{2}\";\r\nContent-Type: {3}\r\n\r\n", 
					boundary, 
					param.Key, 
					fileToUpload.FileName ?? param.Key, 
					fileToUpload.ContentType ?? "application/octet-stream");
 
				formDataStream.Write(encoding.GetBytes(header), 0, header.Length);
 
				// Write the file data directly to the Stream, rather than serializing it to a string.
				formDataStream.Write(fileToUpload.File, 0, fileToUpload.File.Length);
			}
			else
			{
				string postData = string.Format("--{0}\r\nContent-Disposition: form-data; name=\"{1}\"\r\n\r\n{2}\r\n", 
					boundary, 
					param.Key, 
					param.Value);
				formDataStream.Write(encoding.GetBytes(postData), 0, postData.Length);
			}
		}
 
		// Add the end of the request
		string footer = "\r\n--" + boundary + "--\r\n";
		formDataStream.Write(encoding.GetBytes(footer), 0, footer.Length);
 
		// Dump the Stream into a byte[]
		formDataStream.Position = 0;
		byte[] formData = new byte[formDataStream.Length];
		formDataStream.Read(formData, 0, formData.Length);
		formDataStream.Close();
 
		return formData;
	}
 
	public class FileParameter
	{
		public byte[] File { get; set; }
		public string FileName { get; set; }
		public string ContentType { get; set; }
		public FileParameter(byte[] file) : this(file, null) { }
		public FileParameter(byte[] file, string filename) : this(file, filename, null) { }
		public FileParameter(byte[] file, string filename, string contenttype) 
		{
			File = file;
			FileName = filename;
			ContentType = contenttype;
		}
	}
}

/////////////

/*

// Read file data
FileStream fs = new FileStream("c:\\people.doc", FileMode.Open, FileAccess.Read);
byte[] data = new byte[fs.Length];
fs.Read(data, 0, data.Length);
fs.Close();
 
// Generate post objects
Dictionary<string, object> postParameters = new Dictionary<string, object>();
postParameters.Add("filename", "People.doc");
postParameters.Add("fileformat", "doc");
postParameters.Add("file", new FormUpload.FileParameter(data, "People.doc", "application/msword"));
 
// Create request and receive response
string postURL = "http://localhost";
string userAgent = "Someone";
HttpWebResponse webResponse = FormUpload.MultipartFormDataPost(postURL, userAgent, postParameters);
 
// Process response
StreamReader responseReader = new StreamReader(webResponse.GetResponseStream());
string fullResponse = responseReader.ReadToEnd();
webResponse.Close();
Response.Write(fullResponse);

*/

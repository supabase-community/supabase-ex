Deno.serve(async (req) => {
  try {
    const formData = await req.formData();

    const result: Record<string, any> = {
      fields: {},
      files: []
    };

    // Process all form data entries
    for (const [key, value] of formData.entries()) {
      if (value instanceof File) {
        // Handle file uploads
        const fileInfo = {
          fieldName: key,
          fileName: value.name,
          fileType: value.type,
          fileSize: value.size,
          // Optionally read file content (for small files)
          content: value.size < 1024 * 1024 // Only include content for files < 1MB
            ? await value.text()
            : "[File too large to display]"
        };
        result.files.push(fileInfo);
      } else {
        // Handle regular form fields
        result.fields[key] = value;
      }
    }

    return new Response(JSON.stringify(result, null, 2), {
      status: 200,
      headers: { "Content-Type": "application/json" }
    });
  } catch (error) {
    return new Response(JSON.stringify({
      error: "Failed to parse multipart form data",
      message: error.message
    }), {
      status: 400,
      headers: { "Content-Type": "application/json" }
    });
  }
});

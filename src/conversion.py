import win32com
import win32com.client as win32
import os


def document_conversion(file_name: str, extensions: list[str]=None) -> list[str]:
    """
    Convert a document to PDF using Microsoft Word
    @param file_name: The relative or absolute filename of the file that you would like to convert.  This file must be openable by 
    Microsoft Word.
    @param extensions: A list of extensions that you would like to provide the extractions of.  Currently 'txt' and 'pdf' are the only
    extensions supported.
    @return: A list of filenames that contain the original file contents in the format desired.  The order of the list will be in the same 
    order as the `extensions` variable.
    """
    if extensions is None:
        extensions = ["txt", "pdf"]

    full_path = os.path.abspath(file_name)

    office_app = win32.gencache.EnsureDispatch('Word.Application')
    doc = office_app.Documents.Open(full_path)

    extension_format = {'txt': win32.constants.wdFormatUnicodeText,
                                        'pdf': win32.constants.wdFormatPDF}

    without_extension, _ = os.path.splitext(full_path)

    returned_files = []
    for extension in extensions:
        new_filename = without_extension + "." + extension
        doc.saveAs(new_filename, extension_format[extension])
        returned_files.append(new_filename)

    office_app.Quit()
    return returned_files


def presentation_conversion(file_name: str, extensions: list[str]=None) -> list[str]:
    """
    Convert a presentation to PDF using Microsoft PowerPoint
    @param file_name: The relative or absolute filename of the file that you would like to convert.  This file must be openable by 
    Microsoft PowerPoint.
    @param extensions: A list of extensions that you would like to provide the extractions of.  Currently 'txt' and 'pdf' are the only
    extensions supported.
    @return: A list of filenames that contain the original file contents in the format desired.  The order of the list will be in the same 
    order as the `extensions` variable.
    """
    if extensions is None:
        extensions = ["txt", "pdf"]
    full_path = os.path.abspath(file_name)

    office_app = win32.gencache.EnsureDispatch('Powerpoint.Application')
    presentation = office_app.Presentations.Open(full_path)

    extension_format = {'txt': win32.constants.ppSaveAsRTF,
                                        'pdf': win32.constants.ppSaveAsPDF}

    without_extension, _ = os.path.splitext(full_path)

    returned_files = []
    for extension in extensions:
        new_filename = without_extension + "." + extension
        presentation.saveAs(new_filename, extension_format[extension])
        if extension == 'txt':
            """
            Powerpoint does not allow conversion to text, so we must convert to RTF and then perform a subsequent conversion to text.
            """
            new_filename = document_conversion(new_filename, ['txt'])[0]  # reduce the list to a single element.
        returned_files.append(new_filename)

    office_app.Quit()
    return returned_files


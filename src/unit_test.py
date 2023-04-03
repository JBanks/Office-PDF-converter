import os
import unittest
import conversion

test_document_content = """English
English
French
français
Arabic
عربى
Chinese
中国人 中國人
🐻☃👨🏿‍🦰🎅🏿"""

test_presentation_content = """Branch and Bound
2Lt Jeremy Banks
Application to research
• Solving the WTA problem
• Used by Gibbons (who took their solution from Ahuja)
• "has become the most commonly used tool for solving NP-hard optimization problems" - Wikipedia
• Searching for a faster way to achieve optimums

The algorithm
The algorithm
Use an upper-bound heuristic and store that solution as the Best-So-Far
The algorithm
Use an upper-bound heuristic and store that solution as the Best-So-Far
Add all of the nodes in the heuristic solution to a stack
The algorithm
Use an upper-bound heuristic and store that solution as the Best-So-Far
Add all of the nodes in the heuristic solution to a stack
Pop the last node in the stack
	If the node is terminal, evaluate it and compare it with B
		Store better solutions, discard all others
The algorithm
Use an upper-bound heuristic and store that solution as the Best-So-Far
Add all of the nodes in the heuristic solution to a stack
Pop the last node in the stack
	If the node is terminal, evaluate it and compare it with B
		Store better solutions, discard all others
	If the node is non-terminal, branch on that node
		Calculate lower-bounds on the child nodes
			If the lower-bound > B, we discard that node
			otherwise it goes into the queue
A*
Use an upper-bound heuristic and store that as the Best-So-Far
Add all of the nodes in the heuristic solution to a stack
Pop the last node in the stack
	If the node is terminal, evaluate it and compare it with B
		Store better solutions, discard all others
	If the node is non-terminal, branch on that node
		Calculate lower-bounds on the child nodes
			If the lower-bound > B, we discard that node
			otherwise it goes into the queue
Comparison
• Both algorithms can be admissible (capable of guaranteeing optimality)
• A* will need to hold all visited nodes, and all frontier nodes and search each list on every node expansion
• A* will visit all nodes that are closer than the goal, while B&B may visit nodes that are further than the optimal solution with growth relative to the following equation:
𝐵𝑟𝑎𝑛𝑐ℎ𝐹𝑎𝑐𝑡𝑜﷐𝑟﷮﷐𝐻𝑒𝑢𝑟𝑖𝑠𝑡𝑖𝑐𝐿𝑒𝑛𝑔𝑡ℎ−𝑂𝑝𝑡𝑖𝑚𝑎𝑙𝐿𝑒𝑛𝑔𝑡ℎ﷯﷯
Why not just use A*?
• Time constraints
• Memory Constraints
• Practice makes perfect
Summary
• Can guarantee an optimal solution
• Searches the space and doesn't need to reach completion for a valid solution
• Lower memory requirements than A*

"""


class WindowsConversionTest(unittest.TestCase):

    def test_document_conversion_returns_list(self):
        test_file = "Test_documents/Test_document.docx"
        full_path = os.path.abspath(test_file)
        without_extension, _ = os.path.splitext(full_path)
        confirmation_list = [without_extension + ".pdf", without_extension + ".txt"]
        files = conversion.document_conversion(test_file)
        self.assertCountEqual(files, confirmation_list)

    def test_presentation_conversion_returns_list(self):
        test_file = "Test_documents/algorithm.pptx"
        full_path = os.path.abspath(test_file)
        without_extension, _ = os.path.splitext(full_path)
        confirmation_list = [without_extension + ".pdf", without_extension + ".txt"]
        files = conversion.presentation_conversion(test_file)
        self.assertCountEqual(files, confirmation_list)

    def test_document_text_extraction(self):
        test_file = "Test_documents/Test_document.docx"
        filename = conversion.document_conversion(test_file, extensions=['txt'])[0]
        file = open(filename, 'r')
        content = file.read()
        self.assertEqual(content, test_document_content)

    def test_presentation_text_extraction(self):
        test_file = "Test_documents/algorithm.pptx"
        filename = conversion.presentation_conversion(test_file, extensions=['txt'])[0]
        file = open(filename, 'r')
        content = file.read()
        self.assertEqual(content, test_presentation_content)

    def test_document_pdf_conversion(self):
        """
        I don't have a method to verify that the file has been converted correctly to PDF.
        """
        pass

    def test_presentation_pdf_conversion(self):
        """
        I don't have a method to verify that the file has been converted correctly to PDF.
        """
        pass


if __name__ == "__main__":
    unittest.main()

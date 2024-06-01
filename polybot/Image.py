import random
from pathlib import Path
from matplotlib.image import imread, imsave
from loguru import logger


class Image:
    def __init__(self, path):
        self.path = Path(path)
        self.data = self.rgb2gray(imread(path)).tolist()

    @staticmethod
    def rgb2gray(rgb):
        r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
        gray = 0.2989 * r + 0.5870 * g + 0.1140 * b
        return gray

    def save_img(self):
        new_path = self.path.with_name(self.path.stem + '_filtered' + self.path.suffix)
        imsave(new_path, self.data, cmap='gray')
        return new_path

    def handle_filter(self, filter_name, **kwargs):
        """
        Dynamically executes a filter method based on its name.

        Args:
        - filter_name (str): The name of the filter method to run.
        - **kwargs: Optional keyword arguments to pass to the filter method.

        Returns:
        - The result of the filter method, if any.

        Raises:
        - AttributeError: If the specified filter method does not exist.
        """
        # Dynamically fetch the method by name
        method = getattr(self, filter_name, None)

        if not method:
            raise AttributeError(f"Filter method '{filter_name}' not found.")

        # Call the method if it exists, passing any additional keyword arguments
        return method(**kwargs)

    def blur(self, blur_level=16):

        logger.info('try blur')

        height = len(self.data)
        width = len(self.data[0])
        filter_sum = blur_level ** 2

        result = []
        for i in range(height - blur_level + 1):
            row_result = []
            for j in range(width - blur_level + 1):
                sub_matrix = [row[j:j + blur_level] for row in self.data[i:i + blur_level]]
                average = sum(sum(sub_row) for sub_row in sub_matrix) // filter_sum
                row_result.append(average)
            result.append(row_result)

        self.data = result

    def contour(self):
        for i, row in enumerate(self.data):
            res = []
            for j in range(1, len(row)):
                res.append(abs(row[j - 1] - row[j]))

            self.data[i] = res

    def rotate(self, direction='clockwise'):
        """
        Rotate the image in the specified direction.

        :param direction: 'clockwise' or 'counterclockwise'
        """

        # Transpose the image for both directions
        self._transpose()

        if direction == 'clockwise':
            # For clockwise rotation, reverse the rows after transposing
            self._reverse_rows()
        elif direction == 'counterclockwise':
            # For counterclockwise rotation, reverse the columns (the whole image here) after transposing
            self._reverse_columns()

    def salt_n_pepper(self):
        """
        Add salt and pepper noise to the image based on the specified algorithm. (see comments below)
        """
        height = len(self.data)
        width = len(self.data[0])

        for i in range(height):
            for j in range(width):
                rand = random.random()
                if rand < 0.2:
                    self.data[i][j] = 255  # Set to maximum intensity for 'salt'
                elif rand > 0.8:
                    self.data[i][j] = 0  # Set to minimum intensity for 'pepper'
                # If the random number is between 0.2 and 0.8, do nothing (keep the original pixel value)

    def segment(self):
        """
        Segment the image by setting pixel values to white (255) if their intensity is greater than 100,
        or to black (0) otherwise.
        """
        for i in range(len(self.data)):
            for j in range(len(self.data[i])):
                self.data[i][j] = 255 if self.data[i][j] > 100 else 0

    def _transpose(self):
        """
        Transpose the image (swap rows with columns).
        """
        self.data = list(map(list, zip(*self.data)))

    def _reverse_rows(self):
        """
        Reverse each row in the image.
        """
        self.data = [row[::-1] for row in self.data]

    def _reverse_columns(self):
        """
        Reverse each column in the image.
        This can be done by reversing the entire image.
        """
        self.data.reverse()
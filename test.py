import os
from tkinter import *
from PIL import Image, ImageTk

class ImageViewer:
    def __init__(self, master):
        self.master = master
        self.master.title("Image Viewer")
        self.master.geometry("600x400")

        self.image_paths = self.load_image_paths("D:/") # Thay đổi 'images' thành đường dẫn của thư mục chứa ảnh của bạn
        self.current_index = 0

        self.display_image()

        self.master.bind("<Left>", self.prev_image)
        self.master.bind("<Right>", self.next_image)

    def load_image_paths(self, directory):
        image_paths = []
        for filename in os.listdir(directory):
            if filename.endswith(".png") or filename.endswith(".jpg"):
                image_paths.append(os.path.join(directory, filename))
        return image_paths

    def display_image(self):
        image_path = self.image_paths[self.current_index]
        image = Image.open(image_path)
        photo = ImageTk.PhotoImage(image)

        if hasattr(self, 'label'):
            self.label.destroy()

        self.label = Label(self.master, image=photo)
        self.label.image = photo
        self.label.pack()

    def next_image(self, event):
        if self.current_index < len(self.image_paths) - 1:
            self.current_index += 1
        else:
            self.current_index = 0
        self.display_image()

    def prev_image(self, event):
        if self.current_index > 0:
            self.current_index -= 1
        else:
            self.current_index = len(self.image_paths) - 1
        self.display_image()

def main():
    root = Tk()
    app = ImageViewer(root)
    root.mainloop()

if __name__ == "__main__":
    main()

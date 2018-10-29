# BluRip

BD to downsampled / transcoded MP4 via the magic of Docker

This combines the awesomeness of MakeMKV and HandBrake into a single handy tool for end-to-end video extraction.

Make sure you have enough space free, then `make run`

The docker file will be built if it's not already there, and the script will copy all segments longer than 1000 seconds to `output/`.

You can change the encoding preferences and minimum length, instructions forthcoming.

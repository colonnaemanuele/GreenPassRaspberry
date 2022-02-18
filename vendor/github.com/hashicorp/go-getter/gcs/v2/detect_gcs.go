package gcs

import (
	"fmt"
	"net/url"
	"strings"
)

// Detector implements Detector to detect GCS URLs and turn
// them into URLs that the GCSGetter can understand.
type Detector struct{}

func (d *Detector) Detect(src, _ string) (string, bool, error) {
	if len(src) == 0 {
		return "", false, nil
	}

	if strings.Contains(src, "googleapis.com/") {
		return d.detectHTTP(src)
	}

	return "", false, nil
}

func (d *Detector) detectHTTP(src string) (string, bool, error) {

	parts := strings.Split(src, "/")
	if len(parts) < 5 {
		return "", false, fmt.Errorf(
			"URL is not a valid GCS URL")
	}
	version := parts[2]
	bucket := parts[3]
	object := strings.Join(parts[4:], "/")

	url, err := url.Parse(fmt.Sprintf("https://www.googleapis.com/storage/%s/%s/%s",
		version, bucket, object))
	if err != nil {
		return "", false, fmt.Errorf("error parsing GCS URL: %s", err)
	}

	return url.String(), true, nil
}

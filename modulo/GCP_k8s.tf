{
  "locals": [
    {
      "test_description": "No GCP cluster has legacy authorization enabled"
    }
  ],
  "resource": [
    {
      "google_container_cluster": [
        {
          "x": [
            {
              "initial_node_count": 3,
              "location": "us-central1-a",
              "name": "marcellus-wallace"
            }
          ]
        }
      ]
    },
    {
      "google_container_cluster": [
        {
          "y": [
            {
              "addons_config": [
                {
                  "istio_config": [
                    {
                      "auth": "AUTH_MUTUAL_TLS",
                      "disabled": false
                    }
                  ]
                }
              ],
              "initial_node_count": 3,
              "location": "us-central1-a",
              "name": "marcellus-wallace"
            }
          ]
        }
      ]
    }
  ]
}

name: Deploy Nginx on Podman
  hosts: localhost
  become: true
  tasks:
    - name: Ensure Podman is installed
      ansible.builtin.package:
        name: podman
        state: present

    - name: Pull Nginx image
      containers.podman.podman_image:
        name: docker.io/library/nginx:latest
        state: present

    - name: Run Nginx container
      containers.podman.podman_container:
        name: nginx
        image: docker.io/library/nginx:latest
        state: started
        ports:
          - "80:80"

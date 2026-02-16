FROM python:3.12-alpine
WORKDIR /app
COPY vpn-leak-check.py /app/vpn-leak-check.py
ENV PORT=8090
EXPOSE 8090
CMD ["python", "/app/vpn-leak-check.py"]
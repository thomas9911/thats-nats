use async_nats::jetstream::consumer;
use futures_util::StreamExt;

const STREAM_NAME: &str = "testing";
const CONSUMER_NAME: &str = "rust";

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let nc = async_nats::connect("nats://127.0.0.1:4222").await?;
    let js = async_nats::jetstream::new(nc);

    let js_stream = js.get_or_create_stream(STREAM_NAME).await?;
    let consumer = js_stream.get_or_create_consumer(CONSUMER_NAME, consumer::pull::Config{durable_name: Some(CONSUMER_NAME.to_string()), ..Default::default()}).await?;

    let mut messages = consumer
        .stream()
        .max_messages_per_batch(100)
        .max_bytes_per_batch(1024)
        .messages()
        .await?;

    while let Some(message) = messages.next().await {
        let message = message?;
        println!("got message {:?}", message);

        message.ack().await.map_err(|e| anyhow::anyhow!(e))?;
    }

    Ok(())
}

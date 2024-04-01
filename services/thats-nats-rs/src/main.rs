// use async_nats::jetstream::consumer;
use futures_util::StreamExt;

// const STREAM_NAME: &str = "testing";
// const CONSUMER_NAME: &str = "rust";

// #[tokio::main]
// async fn main() -> anyhow::Result<()> {
//     let nc = async_nats::connect("nats://127.0.0.1:4222").await?;
//     let js = async_nats::jetstream::new(nc);

//     let js_stream = js.get_or_create_stream(STREAM_NAME).await?;
//     let consumer = js_stream.get_or_create_consumer(CONSUMER_NAME, consumer::pull::Config{durable_name: Some(CONSUMER_NAME.to_string()), ..Default::default()}).await?;

//     let mut messages = consumer
//         .stream()
//         .max_messages_per_batch(100)
//         .max_bytes_per_batch(1024)
//         .messages()
//         .await?;

//     let nc = async_nats::connect("nats://127.0.0.1:4222").await?;

//     while let Some(message) = messages.next().await {
//         let message = message?;
//         println!("got message {:?}", message);

//         if let Some(reply) = &message.reply {
//             // nc.publish_with_reply(STREAM_NAME, reply.as_str().to_string(), "from rust".into()).await?;
//             nc.publish(reply.as_str().to_string(), "I can help!".into()).await?;

//         }

//         message.ack().await.map_err(|e| anyhow::anyhow!(e))?;

//     }

//     Ok(())
// }

// use rhai::Engine;
// use rhai::packages::Package;
// use rhai_rand::RandomPackage;

// const CHANNEL_NAME: &str = "rust";

// #[tokio::main]
// async fn main() -> anyhow::Result<()> {
//     // let nc = async_nats::connect("nats://127.0.0.1:4222").await?;
//     let nc = async_nats::ConnectOptions::new()
//     .no_echo()
//     .connect("nats://127.0.0.1:4222")
//     .await?;

//     let mut messages = nc.subscribe(CHANNEL_NAME).await?;
//     let mut engine = Engine::new();
//     let random = RandomPackage::new();
//     random.register_into_engine(&mut engine);

//     while let Some(message) = messages.next().await {
//         println!("got message {:?}", message);

//         if let Some(reply) = &message.reply {
//             let payload = std::str::from_utf8(&message.payload)?;
//             let out = match engine.eval::<rhai::Dynamic>(&payload){
//                 Ok(res) => format!(r#"{{"result": {}}}"#, serde_json::to_string(&res)?),
//                 Err(err) => format!(r#"{{"error": "{}"}}"#, err.to_string()),
//             };
//             nc.publish(reply.as_str().to_string(), out.into()).await?;
//         }
//     }

//     Ok(())
// }

use rhai::packages::Package;
use rhai::Engine;
use rhai_rand::RandomPackage;

use async_nats::service::ServiceExt;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let nc = async_nats::ConnectOptions::new()
        .no_echo()
        .connect("nats://127.0.0.1:4222")
        .await?;

    let service = nc
        .service_builder()
        .description("run a rhai script")
        .start("rhai_aas", "0.1.0")
        .await
        .map_err(|e| anyhow::anyhow!(e))?;
    let mut endpoint = service
        .group("rhai")
        .endpoint("run")
        .await
        .map_err(|e| anyhow::anyhow!(e))?;

    let mut engine = Engine::new();
    let random = RandomPackage::new();
    random.register_into_engine(&mut engine);

    while let Some(request) = endpoint.next().await {
        if let Some(reply) = &request.message.reply {
            let payload = std::str::from_utf8(&request.message.payload)?;
            let out = match engine.eval::<rhai::Dynamic>(&payload) {
                Ok(res) => format!(r#"{{"result": {}}}"#, serde_json::to_string(&res)?),
                Err(err) => format!(r#"{{"error": "{}"}}"#, err.to_string()),
            };
            nc.publish(reply.as_str().to_string(), out.into()).await?;
        }
    }

    Ok(())
}

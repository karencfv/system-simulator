use futures::Future;
use rand_distr::{Distribution, Normal};
use std::time::Duration;

pub type PersistIdent = u64;

pub struct Persist {
    rng: Normal<f64>,
}

pub const PERSIST_N: usize = 8;

impl Persist {
    pub fn new() -> Self {
        Self {
            rng: Normal::new(10_000.0, 5_000.0).unwrap(),
        }
    }

    pub fn enqueue(&self, id: PersistIdent, handler: impl Future + Send + 'static) {
        isim_persist__start!(|| id);
        let d = self.rng.sample(&mut rand::thread_rng()) as u64;
        let delta = Duration::from_micros(50_000 + d);
        // Asynchronously delay for the time required to complete a transaction
        // and then call the completion handler.
        tokio::task::spawn(async move {
            isim_persist__async__start!(|| id);
            tokio::time::sleep(delta).await;
            isim_persist__done!(|| id);
            handler.await;
        }); //.await.unwrap(); // we should wait for the store transaction to finish?
    }
}

use std::sync::{
    atomic::{AtomicU64, Ordering},
    Arc,
};
use tokio::sync::Semaphore;

use crate::persist::{Persist, PERSIST_N};

pub struct DataProcessor {
    sem: Arc<Semaphore>,
    id: AtomicU64,
    persist: Persist,
}
impl DataProcessor {
    pub fn new() -> Self {
        let persist = Persist::new();

        let ret = Self {
            sem: Arc::new(Semaphore::new(PERSIST_N)),
            id: AtomicU64::new(5),
            persist,
        };

        ret
    }
    pub async fn request(&self, id: u64) {
        // Wait until we can be sure we have a slot available in the persistent
        // store i.e. that the enqueue will succeed. We eliminate the
        // reservation and restore it when the transaction is complete.
        let sem = self.sem.clone();

        // We first try to acquire the semaphore in a non-blocking fashion
        // simply so that we can determine whether this is a blocking or
        // non-blocking request for the semaphore.
        match sem.try_acquire() {
            Ok(s) => {
                isim_request__nonblock!(|| id);
                s
            }
            Err(_) => {
                isim_request__block!(|| id);
                sem.acquire().await.unwrap()
            }
        }
        .forget();

        // Increment the id.
        let id = self.id.fetch_add(1, Ordering::SeqCst);

        // Enqueue the transaction with the persistent store.
        let sem = self.sem.clone();
        self.persist.enqueue(id, async move {
            sem.add_permits(1);
        });

        // Return to the caller without waiting for the transaction to
        // complete.
    }
}

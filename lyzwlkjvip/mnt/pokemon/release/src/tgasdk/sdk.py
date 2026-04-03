# -*- coding: utf-8 -*-
class _BaseConsumer(object):
    def __init__(self, *args, **kwargs):
        self.args = args
        self.kwargs = kwargs
    def close(self):
        return None
class LoggingConsumer(_BaseConsumer):
    pass
class BatchConsumer(_BaseConsumer):
    pass
class AsyncBatchConsumer(_BaseConsumer):
    pass
class TGAnalytics(object):
    def __init__(self, consumer):
        self.consumer = consumer
    def track(self, account_id=None, event_name=None, properties=None):
        return None
    def user_set(self, account_id=None, properties=None):
        return None
    def user_setOnce(self, account_id=None, properties=None):
        return None
    def flush(self):
        return None

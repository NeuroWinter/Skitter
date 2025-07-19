# Just a list of random notes for myself

## Tracing

### qtrace

It looks like when I just call `plot_all_histograms/1` I am getting errors. The work around for this is to run the following:

```
session = Qtrace.start_session(:all)
Qtrace.trace_function(session, Skitter.CrawlerWorker, :crawl, 1)

Skitter.set_seed("https://neurowinter.com")

hist = Qtrace.get_histogram(session, Skitter.CrawlerWorker, :crawl, 1)
Qtrace.Plotter.plot_histogram(hist)
```

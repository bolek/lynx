Hammox.defmock(ConcreteAdapter, for: Lynx.Adapter)

File.rm_rf!("./test/tmp/")

ExUnit.start()

import AssemblyKeys._

assemblySettings

name := "sparkles"

version := "0.0.1"

scalaVersion := "2.11.4"

libraryDependencies += "org.elasticsearch" % "elasticsearch-hadoop" % "2.0.2" // "2.1.0.Beta3"

resolvers += "Clojars" at "http://conjars.org/repo"

mergeStrategy in assembly <<= (mergeStrategy in assembly) { (old) =>
  {
    case m if m.toLowerCase.endsWith("manifest.mf") => MergeStrategy.discard
    case m if m.startsWith("META-INF") => MergeStrategy.discard
    case PathList("javax", "servlet", xs @ _*) => MergeStrategy.first
    case PathList("org", "apache", xs @ _*) => MergeStrategy.first
    case PathList("org", "jboss", xs @ _*) => MergeStrategy.first
    case "about.html"  => MergeStrategy.rename
    case "reference.conf" => MergeStrategy.concat
    case _ => MergeStrategy.first
  }
}

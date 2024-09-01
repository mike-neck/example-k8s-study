package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	d := flag.String("d", "", "root directory, requires existing directory, has permission to read, not empty")
	p := flag.Int("p", 8080, "port number, requires positive value, none-privileged port number, free port number")
	h := flag.Bool("h", false, "shows this help")

	flag.Parse()
	if *h {
		flag.Usage()
		os.Exit(0)
	}

	if *p < 1024 {
		showError("-p options(port number) should be positive and none-privileged")
		os.Exit(1)
	}

	if *d == "" {
		showError("-d option(directory path) is required")
		os.Exit(1)
	}

	stat, err := os.Stat(*d)
	if err != nil || !stat.IsDir() {
		showError("-d option(directory path) should be existing directory with permissions")
		os.Exit(1)
	}

	// 静的ファイルを提供するディレクトリを設定
	dir := *d
	port := *p

	// ファイルサーバーのハンドラーを作成
	fs := http.FileServer(http.Dir(dir))

	// カスタムハンドラーでファイルが見つからない場合にpanicを発生させる
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		path := r.URL.Path
		_, err := os.Stat(dir + path)
		log.Printf("%s %s\n", r.Method, path)
		if os.IsNotExist(err) {
			log.Fatal(fmt.Sprintf("File not found: %s", path))
		}
		fs.ServeHTTP(w, r)
	})

	// サーバーを起動
	fmt.Printf("Starting server at port %d\n", port)
	if err := http.ListenAndServe(fmt.Sprintf(":%d", port), nil); err != nil {
		log.Fatal(err)
	}
}

func showError(msg string) {
	_, _ = os.Stderr.WriteString(msg)
	flag.CommandLine.SetOutput(os.Stderr)
	flag.Usage()
}

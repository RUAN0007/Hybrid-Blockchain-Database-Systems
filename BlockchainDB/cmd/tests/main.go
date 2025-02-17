package main

import (
	"context"
	"flag"
	"fmt"
	"sync"
	"time"

	pbv "hybrid/BlockchainDB/proto/blockchaindb"

	"google.golang.org/grpc"
)

func main() {
	//local testing mode
	//addr := "127.0.0.1:50001"

	// ovs multi_node testing mode
	//addr := "192.168.20.2:50001"
	addr := flag.String("addr", "192.168.20.2:50001", "bcdb server node address")
	flag.Parse()
	key := "tianwen" + time.Now().Format("20060102150405")
	value := "66666666666666666666666666"

	conn, err := grpc.Dial(*addr, grpc.WithInsecure())
	if err != nil {
		panic(err)
	}
	cli := pbv.NewBCdbNodeClient(conn)

	start := time.Now()
	res, err := cli.Set(context.Background(), &pbv.SetRequest{Key: key, Value: value})
	if err != nil {
		fmt.Println(err)
	} else {
		fmt.Println(res.Tx)
	}
	fmt.Println("1.BlockchainDB Set done.")

	counter := 0
	for {
		counter += 1
		res1, err := cli.Get(context.Background(), &pbv.GetRequest{Key: key})
		if err != nil {
			fmt.Println(err)
			break
		}

		if string(res1.Value) != "" {
			fmt.Println(string(res1.Value))
			elapsed := time.Since(start)
			fmt.Printf("Tx set-get took %s\n", elapsed)
			break
		}
	}
	fmt.Println("read query round ", counter)
	fmt.Println("2.Blockchain Get done.")

	lastkey := key
	lastopt := "set"
	lasttx := res.Tx
	wg3 := sync.WaitGroup{}
	wg3.Add(1)
	go func() {
		defer wg3.Done()
		for {
			if lastkey == "" || lastopt == "" || lasttx == "" {
				fmt.Println("No setopt tx to verify .")
				break
			}
			verify, err := cli.Verify(context.Background(), &pbv.VerifyRequest{Opt: lastopt, Key: lastkey, Tx: lasttx})
			if err != nil {
				fmt.Println(err)
			} else {
				if verify != nil && verify.Success {
					fmt.Println("Last tx verify success.")
				} else {
					fmt.Println("Last tx verify stop.")
				}
				break
			}

			time.Sleep(2 * time.Second)
		}
	}()
	wg3.Wait()
	fmt.Println("3.BlockchainDB verify done.")
}

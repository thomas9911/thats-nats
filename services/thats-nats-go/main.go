package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"reflect"
	"strings"

	"github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/micro"

	"github.com/traefik/yaegi/interp"
	"github.com/traefik/yaegi/stdlib"
)

func main() {
	ctx := context.Background()

	url, exists := os.LookupEnv("NATS_URL")
	if !exists {
		url = nats.DefaultURL
	} else {
		url = strings.TrimSpace(url)
	}

	if strings.TrimSpace(url) == "" {
		url = nats.DefaultURL
	}

	nc, err := nats.Connect(url)
	if err != nil {
		log.Fatal(err)
		return
	}
	defer nc.Close()

	srv, err := micro.AddService(nc, micro.Config{
		Name:        "go_aas",
		Version:     "0.0.1",
		Description: "Run request as a go 'script'",
	})
	defer srv.Stop()

	fmt.Printf("Created service: %s (%s)\n", srv.Info().Name, srv.Info().ID)

	if err != nil {
		log.Fatal(err)
		return
	}

	root := srv.AddGroup("go")

	root.AddEndpoint("run", micro.HandlerFunc(handleRequest))
	<-ctx.Done()
}

func handleRequest(req micro.Request) {
	i := interp.New(interp.Options{})

	i.Use(stdlib.Symbols)

	parts := strings.Split(string(req.Data()), ";")

	var out2 reflect.Value
	for _, line := range parts {
		out, err := i.Eval(line)
		if err != nil {
			res := ServiceResult{Error: err.Error()}
			req.RespondJSON(res)
			return
		}
		out2 = out
	}

	res := ServiceResult{Result: valueToJSON(out2)}
	req.RespondJSON(res)
}

func decode(msg *nats.Msg) ServiceResult {
	var res ServiceResult
	json.Unmarshal(msg.Data, &res)
	return res
}

type ServiceResult struct {
	Result interface{} `json:"result,omitempty"`
	Error  string      `json:"error,omitempty"`
}

func valueToJSON(value reflect.Value) interface{} {
	switch value.Kind() {
	case reflect.Invalid:
		return nil
	case reflect.Bool:
		return value.Bool()
	case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
		return value.Int()
	case reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64, reflect.Uintptr:
		return value.Uint()
	case reflect.Float32, reflect.Float64:
		return value.Float()
	case reflect.Complex64, reflect.Complex128:
		return value.Complex()
	case reflect.String:
		return value.String()
	case reflect.Array, reflect.Slice:
		var result []interface{}
		for i := 0; i < value.Len(); i++ {
			result = append(result, valueToJSON(value.Index(i)))
		}
		return result
	case reflect.Map:
		result := make(map[string]interface{})
		for _, key := range value.MapKeys() {
			result[key.String()] = valueToJSON(value.MapIndex(key))
		}
		return result
	case reflect.Struct:
		result := make(map[string]interface{})
		for i := 0; i < value.NumField(); i++ {
			fieldName := value.Type().Field(i).Name
			result[fieldName] = valueToJSON(value.Field(i))
		}
		return result
	case reflect.Interface:
		if value.IsNil() {
			return nil
		}
		return valueToJSON(value.Elem())
	default:
		return fmt.Sprintf("Unsupported type: %s", value.Type())
	}
}

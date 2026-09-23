function claude-local --description "Run Claude Code with a local Ollama model"
    set -l model "qwen3-coder"
    set -l proxy_port 4000
    set -l remaining_args

    set -l i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case --model -m
                set -l next (math $i + 1)
                if test $next -le (count $argv)
                    set model $argv[$next]
                    set i (math $i + 2)
                    continue
                end
            case --port -p
                set -l next (math $i + 1)
                if test $next -le (count $argv)
                    set proxy_port $argv[$next]
                    set i (math $i + 2)
                    continue
                end
            case '*'
                set -a remaining_args $argv[$i]
        end
        set i (math $i + 1)
    end

    if not command -q ollama
        echo "Error: ollama is not installed."
        return 1
    end

    if not curl -s http://localhost:11434/api/tags >/dev/null 2>&1
        echo "Starting ollama serve..."
        ollama serve &>/dev/null &
        sleep 2
    end

    set -l proxy_log /tmp/anthropic-to-ollama.log
    echo "Starting proxy on port $proxy_port for model $model..."
    echo "Proxy log: $proxy_log"
    anthropic-to-ollama $proxy_port $model 2>$proxy_log &
    set -l proxy_pid $last_pid

    set -l ready false
    for attempt in (seq 10)
        if curl -s "http://localhost:$proxy_port/health" >/dev/null 2>&1
            set ready true
            break
        end
        if not kill -0 $proxy_pid 2>/dev/null
            echo "Error: proxy crashed on startup. Logs:"
            cat $proxy_log
            return 1
        end
        sleep 0.5
    end

    if test "$ready" != true
        echo "Error: proxy did not become ready. Logs:"
        tail -20 $proxy_log
        kill $proxy_pid 2>/dev/null
        return 1
    end

    echo "Proxy running (PID $proxy_pid). Launching Claude Code with $model..."
    echo ""

    ANTHROPIC_BASE_URL="http://localhost:$proxy_port" ANTHROPIC_MODEL="claude-sonnet-4-6" command claude $remaining_args
    set -l exit_code $status

    echo ""
    echo "Stopping proxy..."
    kill $proxy_pid 2>/dev/null
    wait $proxy_pid 2>/dev/null

    if test $exit_code -ne 0
        echo "Proxy log:"
        tail -30 $proxy_log
    end

    return $exit_code
end

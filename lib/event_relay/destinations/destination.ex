defmodule ER.Destinations.Destination do
  use Ecto.Schema
  import Ecto.Changeset
  alias ER.Events.Topic
  import ER.Config

  @derive {Jason.Encoder,
           only: [
             :id,
             :name,
             :topic_name,
             :topic_identifier,
             :offset,
             :ordered,
             :destination_type,
             :paused,
             :config,
             :group_key
           ]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "destinations" do
    field :name, :string
    field :offset, :integer
    field :ordered, :boolean, default: false
    field(:destination_type, Ecto.Enum, values: [:api, :webhook, :websocket, :file, :topic])
    field :paused, :boolean, default: false
    field :config, :map, default: %{}
    field :config_json, :string, virtual: true
    field :topic_identifier, :string
    field :group_key, :string
    field :signing_secret, :string
    field :query, :string

    belongs_to :topic, Topic, foreign_key: :topic_name, references: :name, type: :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(destination, attrs) do
    destination
    |> cast(attrs, [
      :name,
      :offset,
      :topic_name,
      :ordered,
      :paused,
      :config,
      :config_json,
      :topic_identifier,
      :destination_type,
      :group_key,
      :signing_secret,
      :query
    ])
    |> validate_required([:name, :topic_name, :destination_type])
    |> validate_length(:name, min: 3, max: 255)
    |> unique_constraint(:name)
    |> decode_config()
    |> put_signing_secret()
    |> assoc_constraint(:topic)
    |> validate_inclusion(:destination_type, [:file, :webhook, :websocket, :api, :topic])
  end

  def put_signing_secret(changeset) do
    # we only want to add the signing_secret if there is not one
    if changeset.data.signing_secret == nil do
      put_change(changeset, :signing_secret, ER.Auth.generate_secret())
    else
      changeset
    end
  end

  def api?(%{destination_type: :api}), do: true
  def api?(_), do: false

  def websocket?(%{destination_type: :websocket}), do: true
  def websocket?(_), do: false

  def webhook?(%{destination_type: :webhook}), do: true
  def webhook?(_), do: false

  def s3?(%{destination_type: :s3}), do: true
  def s3?(_), do: false

  def topic?(%{destination_type: :topic}), do: true
  def topic?(_), do: false

  def base_config_schema(:topic) do
    %{
      "$schema" => "http://json-schema.org/draft-04/schema#",
      "title" => "Configuration for a topic destination",
      "description" => "This document records the configuration for a topic destination",
      "type" => "object",
      "properties" => %{
        "topic_name" => %{
          "description" => "The name of the topic that you want to forward events to",
          "type" => "string"
        },
        "pipeline" => config_schema_pipeline()
      }
    }
  end

  def base_config_schema(:file) do
    %{
      "$schema" => "http://json-schema.org/draft-04/schema#",
      "title" => "Configuration for a topic destination",
      "description" => "This document records the configuration for a topic destination",
      "type" => "object",
      "properties" => %{
        "service" => %{
          "description" => "The service you want to send the events to. Ex. s3",
          "type" => "string",
          "default" => "s3"
        },
        "format" => %{
          "description" => "The format of the file pushed to the service. Ex. jsonl",
          "type" => "string",
          "default" => "jsonl"
        },
        "s3" => %{
          "description" => "The configuration for S3",
          "type" => "object",
          "properties" => %{
            "region" => %{
              "description" => "The S3 region your bucket is in",
              "type" => "string"
            },
            "bucket" => %{
              "description" => "The S3 bucket name",
              "type" => "string"
            }
          }
        },
        "pipeline" => config_schema_pipeline()
      }
    }
  end

  def base_config_schema(:webhook) do
    %{
      "$schema" => "http://json-schema.org/draft-04/schema#",
      "title" => "Configuration for a webhook destination",
      "description" => "This document records the configuration for a webhook destination",
      "type" => "object",
      "properties" => %{
        "topic_name" => %{
          "description" => "The name of the topic that you want to forward events to",
          "type" => "string"
        },
        "retries" => %{
          "description" => "Configuration for Webhook Retries",
          "type" => "object",
          "properties" => %{
            "max_interval" => %{
              "description" => "The max interval between retries",
              "type" => "number",
              "default" => 256_000
            },
            "max_attempts" => %{
              "description" => "The max attempts that will be tried",
              "type" => "number",
              "default" => 10
            }
          }
        },
        "pipeline" => config_schema_pipeline()
      }
    }
  end

  defp config_schema_pipeline() do
    %{
      "description" => "Configuration for Destination Pipeline",
      "type" => "object",
      "properties" => %{
        "processor_concurrency" => %{
          "description" =>
            "The number of processes processing the evetnts. The larger the number the greater the throughput of the destination.",
          "type" => "number",
          "default" => 10
        },
        "processor_min_demand" => %{
          "description" =>
            "The minimum number of events the destination will demand when pulling events to process.",
          "type" => "number",
          "default" => 1
        },
        "processor_max_demand" => %{
          "description" =>
            "The maximum number of events the destination will demand when pulling events to process",
          "type" => "number",
          "default" => 50
        },
        "batcher_concurrency" => %{
          "description" => "The number of batching processes to use",
          "type" => "number",
          "default" => 1
        },
        "batch_size" => %{
          "description" => "The number of events to processes in each batch",
          "type" => "number",
          "default" => 50
        },
        "batch_timeout" => %{
          "description" => "How long the batch has to process before it timesout in milliseconds",
          "type" => "number",
          "default" => 1000
        },
        "pull_interval" => %{
          "description" =>
            "How often the destination will pull events to processes in milliseconds",
          "type" => "number",
          "default" => 2000
        }
      }
    }
  end

  def base_config(:webhook) do
    %{
      "endpoint_url" => "http://localhost:4000/webhooks",
      "retries" => %{
        "max_attempts" => 10,
        "max_interval" => 256_000
      },
      "pipeline" => %{
        "processor_concurrency" => 10,
        "processor_min_demand" => 1,
        "processor_max_demand" => 50,
        "batcher_concurrency" => 1,
        "batch_size" => 50,
        "batch_timeout" => 1000,
        "pull_interval" => 2000
      }
    }
  end

  def base_config(:file) do
    %{
      "service" => "s3",
      "bucket" => "...",
      "format" => "jsonl",
      "region" => "...",
      "pipeline" => %{
        "processor_concurrency" => 10,
        "processor_min_demand" => 1,
        "processor_max_demand" => 50,
        "batcher_concurrency" => 1,
        "batch_size" => 50,
        "batch_timeout" => 1000,
        "pull_interval" => 2000
      }
    }
  end

  def base_config(:topic) do
    %{
      "topic_name" => "...",
      "pipeline" => %{
        "processor_concurrency" => 10,
        "processor_min_demand" => 1,
        "processor_max_demand" => 50,
        "batcher_concurrency" => 1,
        "batch_size" => 50,
        "batch_timeout" => 1000,
        "pull_interval" => 2000
      }
    }
  end

  def matches?(%{query: nil}, _event) do
    true
  end

  def matches?(%{query: query}, event) do
    event =
      Map.from_struct(event) |> Map.drop([:topic, :__meta__]) |> ER.atomize_map()

    Predicated.test(query, event)
  end
end
